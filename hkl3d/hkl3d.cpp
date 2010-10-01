/* This file is part of the hkl3d library.
 *
 * The hkl library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The hkl library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the hkl library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (C) 2010      Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 *          Oussama Sboui <oussama.sboui@synchrotron-soleil.fr>
 */

#include <yaml.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>
#include <libgen.h>
#include <g3d/g3d.h>
#include <g3d/quat.h>
#include <g3d/matrix.h>

#include "hkl3d.h"
#include "btBulletCollisionCommon.h"
#include "BulletCollision/Gimpact/btGImpactCollisionAlgorithm.h"
#include "BulletCollision/Gimpact/btGImpactShape.h"

#ifdef USE_PARALLEL_DISPATCHER
# include "BulletMultiThreaded/SpuGatheringCollisionDispatcher.h"
# include "BulletMultiThreaded/PlatformDefinitions.h"
# include "BulletMultiThreaded/PosixThreadSupport.h"
# include "BulletMultiThreaded/SpuNarrowPhaseCollisionTask/SpuGatheringCollisionTask.h"
#endif

/***************/
/* static part */
/***************/

static float identity[] = {1, 0, 0, 0,
			   0, 1, 0, 0,
			   0, 0, 1 ,0,
			   0, 0, 0, 1};

static void yaml_event_fprintf(FILE *f, yaml_event_t *event)
{
	static const char* event_names[] = {
		"YAML_NO_EVENT",
		"YAML_STREAM_START_EVENT",
		"YAML_STREAM_END_EVENT",
		"YAML_DOCUMENT_START_EVENT",
		"YAML_DOCUMENT_END_EVENT",
		"YAML_ALIAS_EVENT",
		"YAML_SCALAR_EVENT",
		"YAML_SEQUENCE_START_EVENT",
		"YAML_SEQUENCE_END_EVENT",
		"YAML_MAPPING_START_EVENT",
		"YAML_MAPPING_END_EVENT"
	};

	fprintf(f, "event.type : %s\n", event_names[event->type]); 
}

/***************/
/* Hkl3DObject */
/***************/

static btTriangleMesh *trimesh_from_g3dobject(G3DObject *object)
{
	btTriangleMesh *trimesh;
	float *vertex;
	GSList *faces;			
	
	trimesh = new btTriangleMesh();
	trimesh->preallocateVertices(object->vertex_count);
	faces = object->faces;
	vertex = object->vertex_data;
	while(faces){
		G3DFace *face;
		
		face = (G3DFace*)faces->data;	
		btVector3 vertex0(vertex[3*(face->vertex_indices[0])],
				  vertex[3*(face->vertex_indices[0])+1],
				  vertex[3*(face->vertex_indices[0])+2]);
		btVector3 vertex1(vertex[3*(face->vertex_indices[1])], 
				  vertex[3*(face->vertex_indices[1])+1], 
				  vertex[3*(face->vertex_indices[1])+2]);
		btVector3 vertex2(vertex[3*(face->vertex_indices[2])],
				  vertex[3*(face->vertex_indices[2])+1], 
				  vertex[3*(face->vertex_indices[2])+2]);		
		trimesh->addTriangle(vertex0, vertex1, vertex2, true);

		faces = g_slist_next(faces);
	}

	return trimesh;
}

static btCollisionShape* shape_from_trimesh(btTriangleMesh *trimesh, int movable)
{
	btCollisionShape* shape;
	
	/*
	 * create the bullet shape depending on the static status or not of the piece
	 * static : do not move
	 * movable : connected to a HklGeometry axis.
	 */
	if (movable >= 0){	
		shape = dynamic_cast<btGImpactMeshShape*>(new btGImpactMeshShape(trimesh));
		shape->setMargin(btScalar(0));
		shape->setLocalScaling(btVector3(1,1,1));
		/* maybe usefull for softbodies (useless for now) */
		(dynamic_cast<btGImpactMeshShape*>(shape))->postUpdate();
		/* needed for the collision and must be call after the postUpdate (doc) */
		(dynamic_cast<btGImpactMeshShape*>(shape))->updateBound();
	}else{
		shape = dynamic_cast<btBvhTriangleMeshShape*>(new btBvhTriangleMeshShape (trimesh, true));
		shape->setMargin(btScalar(0));
		shape->setLocalScaling(btVector3(1,1,1));
	}

	return shape;
}

static btCollisionObject * btObject_from_shape(btCollisionShape* shape)
{
	btCollisionObject *btObject;

	/* create the Object and add the shape */
	btObject = new btCollisionObject();
	btObject->setCollisionShape(shape);
	btObject->activate(true);

	return btObject;
}

static struct Hkl3DObject *hkl3d_object_new(void)
{
	int i;
	struct Hkl3DObject *self = NULL;

	self = HKL_MALLOC(Hkl3DObject);

	// fill the hkl3d object structure.
	self->config = NULL; /* not owned */
	self->id = -1;
	self->axis_name = NULL;
	self->g3dObject = NULL;
	self->meshes = NULL;
	self->btShape = NULL;
	self->btObject = NULL;
	self->color = NULL;
	self->hide = false;
	self->added = false;
	self->selected = false;
	self->movable = false;
	self->is_colliding = false;

	for(i=0; i<16; i++)
		self->transformation[i] = identity[i];

	return self;
}

static void hkl3d_object_free(struct Hkl3DObject *self)
{
	if(!self)
		return;

	/* memory leak in libg3d to move in the config part */
	if(self->g3dObject && self->g3dObject->transformation){
		g_free(self->g3dObject->transformation);
		self->g3dObject->transformation = NULL;
	}
	if(self->color){
		delete self->color;
		self->color = NULL;
	}
	if(self->btObject){
		delete self->btObject;
		self->btObject = NULL;
	}
	if(self->btShape){
		delete self->btShape;
		self->btShape = NULL;
	}
	if(self->meshes){
		delete self->meshes;
		self->meshes = NULL;
	}
	if(self->axis_name){
		free(self->axis_name);
		self->axis_name = NULL;
	}

	free(self);
}

static void hkl3d_object_set_G3DObject(struct Hkl3DObject *self, G3DObject * object, int id)
{
	int i;
	GSList *faces;
	G3DMaterial* material;

	if(!self || !object)
		return;

	/* release btObject */
	if(self->color)
		delete self->color;
	if(self->btObject)
		delete self->btObject;
	if(self->btShape)
		delete self->btShape;
	if(self->meshes)
		delete self->meshes;


	/* first find the right object depending on the id and the name of the object */
	faces = object->faces;
	material = ((G3DFace *)faces->data)->material;
	
	self->g3dObject = object;
	self->meshes = trimesh_from_g3dobject(object);
	self->btShape = shape_from_trimesh(self->meshes, false);
	self->btObject = btObject_from_shape(self->btShape);
	self->color = new btVector3(material->r, material->g, material->b);
	self->hide = object->hide;
	self->added = false;
	self->selected = false;
	self->movable = false;

	/*
	 * if the object already contain a transformation set the Hkl3DObject
	 * transformation with this transformation. Otherwise set it with the
	 * identity
	 */
	if(object->transformation){
		for(i=0; i<16; i++)
			self->transformation[i] = object->transformation->matrix[i];
	}else{
		/* create one as we requiered it to apply our transformations */
		object->transformation = g_new0(G3DTransformation, 1);
		for(i=0; i<16; i++){
			self->transformation[i] = identity[i];
			object->transformation->matrix[i] = identity[i];
		}
	}
}

/* return 0 if identical 1 if not */
static int hkl3d_object_cmp(struct Hkl3DObject *object1,
			    struct Hkl3DObject *object2)
{
	if((object1->config == object2->config)
	   && (object1->id == object2->id))
		return 0;
	else
		return 1;
}

static void hkl3d_object_set_axis_name(struct Hkl3DObject *self, const char *name)
{
	if(!self || !name || self->axis_name == name)
		return;

	if(self->axis_name)
		free(self->axis_name);
	self->axis_name = strdup(name);
}

void hkl3d_object_fprintf(FILE *f, const struct Hkl3DObject *self)
{
	fprintf(f, "Hkl3DObject : %p\n", self);
	fprintf(f, "- config : %p\n", self->config);
	fprintf(f, "- id : %d\n", self->id);
	fprintf(f, "- name : %p (%s)\n", self->axis_name, self->axis_name);
	fprintf(f, "- btObject : %p\n", self->btObject);
	fprintf(f, "- g3dObject : %p\n", self->g3dObject);
	fprintf(f, "- btShape : %p\n", self->btShape);
	fprintf(f, "- meshes : %p\n", self->meshes);
	fprintf(f, "- color : %p\n", self->color);
	fprintf(f, "- is_colliding : %d\n", self->is_colliding);
	fprintf(f, "- hide : %d\n", self->hide);
	fprintf(f, "- added : %d\n", self->added);
	fprintf(f, "- selected : %d\n", self->selected);
	fprintf(f, "- transformation : %p [", self->transformation);
	if(self->transformation){
		int i;

		for(i=0; i<16; i++)
			fprintf(f, " %f", self->transformation[i]);
	}
	fprintf(f, "]\n");
}

static int hkl3d_object_serialize(yaml_document_t *document, const struct Hkl3DObject *self)
{
	char buffer[64];
	int i;
	int map;
	int key;
	int value;
	int seq;

	map = yaml_document_add_mapping(document,
					(yaml_char_t *)YAML_MAP_TAG,
					YAML_BLOCK_MAPPING_STYLE);

	/* Id */
	key = yaml_document_add_scalar(document, 
				       NULL,
				       (yaml_char_t *)"Id", -1, 
				       YAML_PLAIN_SCALAR_STYLE);
		
	sprintf(buffer, "%d", self->id);
	value = yaml_document_add_scalar(document,
					 NULL,
					 (yaml_char_t *)buffer,
					 -1, 
					 YAML_PLAIN_SCALAR_STYLE);
	yaml_document_append_mapping_pair(document, map, key, value);


	/* axis name */
	key = yaml_document_add_scalar(document,
				       NULL,
				       (yaml_char_t *)"Name", 
				       -1, 
				       YAML_PLAIN_SCALAR_STYLE);
	value = yaml_document_add_scalar(document,
					 NULL,
					 (yaml_char_t *)self->axis_name,
					 -1, 
					 YAML_PLAIN_SCALAR_STYLE);
	yaml_document_append_mapping_pair(document, map, key, value);


	/* transformation */
	key = yaml_document_add_scalar(document,
				       NULL,
				       (yaml_char_t *)"Transformation",
				       -1,
				       YAML_PLAIN_SCALAR_STYLE);
	seq = yaml_document_add_sequence(document, 
					 (yaml_char_t *)YAML_SEQ_TAG,
					 YAML_FLOW_SEQUENCE_STYLE);
	for(i=0; i<16; ++i){
		sprintf(buffer, "%f", self->transformation[i]);
		value = yaml_document_add_scalar(document,
						 NULL,
						 (yaml_char_t *)buffer, 
						 -1, 	
						 YAML_PLAIN_SCALAR_STYLE);
		yaml_document_append_sequence_item(document, seq, value);
	}
	yaml_document_append_mapping_pair(document, map, key, seq);
	
	/* hide */
	key = yaml_document_add_scalar(document,
				       NULL,
				       (yaml_char_t *)"Hide",
				       -1,
				       YAML_PLAIN_SCALAR_STYLE);
	if(self->hide)
		value = yaml_document_add_scalar(document,
						 NULL,
						 (yaml_char_t *)"yes",
						 -1,
						 YAML_PLAIN_SCALAR_STYLE);
	else
		value = yaml_document_add_scalar(document,
						 NULL,
						 (yaml_char_t *)"no",
						 -1,
						 YAML_PLAIN_SCALAR_STYLE);
	yaml_document_append_mapping_pair(document, map, key, value);

	return map;
}

static void hkl3d_object_unserialize(yaml_parser_t *parser, yaml_event_t *event, struct Hkl3DObject *self)
{
	int first = 1;
	int state;

	enum state {START, KEY1, VALUE1, KEY2, VALUE2, KEY3, VALUE3, KEY4, VALUE4, DONE};

	state = START;
	while(state != DONE){
		if(!first)
			yaml_parser_parse(parser, event);
		else
 			first = 0;

		switch(event->type){
		case YAML_STREAM_END_EVENT:
		case YAML_MAPPING_END_EVENT:
			state = DONE;
			break;
		case YAML_MAPPING_START_EVENT:
			if (state == START)
				state = KEY1;
			break;
		case YAML_SEQUENCE_START_EVENT:
			if(state == VALUE3){
				int i;

				for(i=0; i<16; ++i){
					yaml_event_delete(event);
					yaml_parser_parse(parser, event);
					self->transformation[i] = atof((const char *)event->data.scalar.value);
				}
				state = KEY4;
			}
			break;
		case YAML_SCALAR_EVENT:
			if(state == KEY1){
				if(!strcmp("Id", (const char *)event->data.scalar.value))
					state = VALUE1;
			}else if(state == VALUE1){
				self->id = atoi((const char *)event->data.scalar.value);
				state = KEY2;
			}else if(state == KEY2){
				if(!strcmp("Name", (const char *)event->data.scalar.value))
					state = VALUE2;
			}else if(state == VALUE2){
				self->axis_name = strdup((const char *)event->data.scalar.value);
				state = KEY3;
			}else if (state == KEY3){
				if(!strcmp("Transformation", (const char *)event->data.scalar.value))
					state = VALUE3;
			}else if (state == KEY4){
				if(!strcmp("Hide", (const char *)event->data.scalar.value))
					state = VALUE4;
			}else if (state == VALUE4){
				self->hide = !strcmp("yes", (const char *)event->data.scalar.value);
			}
			break;
		default:
			break;
		}
		yaml_event_delete(event);
	}
}


static void hkl3d_object_post_unserialize(struct Hkl3DObject *self)
{
	int i;
	G3DObject *object;
	GSList *faces;
	G3DMaterial* material;

	if(!self)
		return;

	/* first find the right object depending on the id and the name of the object */
	object = (G3DObject *)g_slist_nth_data(self->config->model->objects, self->id);
	faces = object->faces;
	material = ((G3DFace *)faces->data)->material;
	
	self->g3dObject = object;
	self->meshes = trimesh_from_g3dobject(object);
	self->btShape = shape_from_trimesh(self->meshes, false);
	self->btObject = btObject_from_shape(self->btShape);
	self->color = new btVector3(material->r, material->g, material->b);
	self->hide = object->hide;
	self->added = false;
	self->selected = false;
	self->movable = false;

	/*
	 * if the object already contain a transformation set the Hkl3DObject
	 * transformation with this transformation. Otherwise set it with the
	 * identity
	 */
	if(object->transformation){
		for(i=0; i<16; i++)
			self->transformation[i] = object->transformation->matrix[i];
	}else{
		/* create one as we requiered it to apply our transformations */
		object->transformation = g_new0(G3DTransformation, 1);
		for(i=0; i<16; i++){
			self->transformation[i] = identity[i];
			object->transformation->matrix[i] = identity[i];
		}
	}
}

/***************/
/* Hkl3DConfig */
/***************/

static struct Hkl3DConfig *hkl3d_config_new(void)
{
	struct Hkl3DConfig *self = NULL;

	self = HKL_MALLOC(Hkl3DConfig);

	self->filename = NULL;
	self->configs = NULL; /* not owned */
	self->objects = NULL;
	self->len = 0;
	self->model = NULL;
	self->context = NULL;

	return self;
}

static void hkl3d_config_free(struct Hkl3DConfig *self)
{
	int i;

	if(!self)
		return;

	free(self->filename);
	for(i=0; i<self->len; ++i)
		hkl3d_object_free(self->objects[i]);
	free(self->objects);
	free(self->model);
	free(self->context);
	free(self);
}

static void hkl3d_config_add_object(struct Hkl3DConfig *self, struct Hkl3DObject *object)
{
	if(!self || !object)
		return;

	object->config = self;
	self->objects = (typeof(self->objects))realloc(self->objects, sizeof(*self->objects) * (self->len + 1));
	self->objects[self->len++] = object;
}

static void hkl3d_config_delete_object(struct Hkl3DConfig *self, struct Hkl3DObject *object)
{
	int i;

	if(!self || !object)
		return;

	for(i=0; i<self->len; ++i)
		if(self->objects[i] == object){
			hkl3d_object_free(object);
			self->len--;
			/* move all above objects of 1 position */
			if(i < self->len)
				memmove(&self->objects[i], &self->objects[i+1], sizeof(*self->objects) * (self->len - i));
		}
}

/* create a new config from a filename, the directory can be NULL */
static struct Hkl3DConfig *hkl3d_config_new_from_filename(const char *filename, const char *directory)
{
	struct Hkl3DConfig *self = NULL;
	char current[PATH_MAX];
	int res;

	if(!filename)
		return NULL;

	self = hkl3d_config_new();

	/* first set the current directory using the directory parameter*/
	getcwd(current, PATH_MAX);
	res = chdir(directory);

	self->context = g3d_context_new();
	self->model = g3d_model_load_full(self->context, filename, 0);

	res = chdir(current);

	if(!self->model){
		hkl3d_config_free(self);
		return NULL;
	}else{
		/* create all the objects of the model */
		GSList *objects;

		objects = self->model->objects;
		while(objects){
			G3DObject *object;

			object = (G3DObject*)objects->data;
			if(object->vertex_count){			
				int id;
				struct Hkl3DObject *hkl3DObject;
			
				id = g_slist_index(self->model->objects, object);
				hkl3DObject = hkl3d_object_new();
				hkl3d_object_set_G3DObject(hkl3DObject, object, id);

				// insert collision Object in collision world
				//self->_btWorld->addCollisionObject(hkl3dObject->btObject);
				//hkl3DObject->added = true;
			
				// remembers objects to avoid memory leak
				hkl3d_config_add_object(self, hkl3DObject);
			}
			objects = g_slist_next(objects);
		}
		self->filename = strdup(filename);
	}
	return self;
}

void hkl3d_config_fprintf(FILE *f, const struct Hkl3DConfig *self)
{
	int i;

	fprintf(f, "Hkl3DConfig : %p\n", self);
	fprintf(f, "- filename : %s\n", self->filename);
	fprintf(f, "- configs : %p\n", self->configs);
	fprintf(f, "- model : %p\n", self->model);
	fprintf(f, "- context : %p\n", self->context);
	fprintf(f, "- objects (%d) : %p\n", self->len, self->objects);
	for(i=0; i<self->len; ++i)
		hkl3d_object_fprintf(f, self->objects[i]);
}

static int hkl3d_config_serialize(yaml_document_t *document, const struct Hkl3DConfig *self)
{
	int i;
	char number[64];
	int map;
	int key;
	int value;
	int seq;

	/* create the property of the root sequence */
	map = yaml_document_add_mapping(document,
					(yaml_char_t *)YAML_MAP_TAG,
					YAML_BLOCK_MAPPING_STYLE);

	/* add the map key1 : value1 to the property */
	key = yaml_document_add_scalar(document,
				       NULL,
				       (yaml_char_t *)"FileName", 
				       -1, 
				       YAML_PLAIN_SCALAR_STYLE);
	value = yaml_document_add_scalar(document,
					 NULL,
					 (yaml_char_t *)self->filename,
					 -1, 
					 YAML_PLAIN_SCALAR_STYLE);
	yaml_document_append_mapping_pair(document, map, key, value);

	/* add the map key1 : seq to the first property */
	key = yaml_document_add_scalar(document,
				       NULL,
				       (yaml_char_t *)"Objects",
				       -1,
				       YAML_PLAIN_SCALAR_STYLE);

	/* create the sequence of objects */
	seq = yaml_document_add_sequence(document,
					 (yaml_char_t *)YAML_SEQ_TAG,
					 YAML_BLOCK_SEQUENCE_STYLE);

	for(i=0; i<self->len; ++i){
		int node;

		node = hkl3d_object_serialize(document, self->objects[i]);
		yaml_document_append_sequence_item(document, seq, node);
	}

	yaml_document_append_mapping_pair(document, map, key, seq);

	return map;
}

static void hkl3d_config_unserialize(yaml_parser_t *parser, yaml_event_t *event, struct Hkl3DConfig *self)
{
	int first = 1;
	int state;

	enum state {START, KEY1, VALUE1, KEY2, WAIT_SEQ, SEQ, DONE};

	state = START;
	while(state != DONE){
		if(!first)
			yaml_parser_parse(parser, event);
		else
			first = 0;

		/* the first things to do is to check for the DONE state */
		switch(event->type){
		case YAML_STREAM_END_EVENT:
		case YAML_MAPPING_END_EVENT:
			state = DONE;
			break;
		}

		/*  now add all the object to the config */
		if (state == SEQ && event->type != YAML_SEQUENCE_END_EVENT){
			Hkl3DObject *object;

			object = hkl3d_object_new();
			hkl3d_object_unserialize(parser, event, object);
			hkl3d_config_add_object(self, object);
			yaml_event_delete(event);
			continue;
		}

		/* treatement of all the event */
		switch(event->type){
		case YAML_MAPPING_START_EVENT:
			if (state == START)
				state = KEY1;
			break;
		case YAML_SEQUENCE_START_EVENT:
			if(state == WAIT_SEQ)
				state = SEQ;
			break;
		case YAML_SCALAR_EVENT:
			if(state == KEY1){
				if(!strcmp("FileName", (const char *)event->data.scalar.value))
					state = VALUE1;
			}else if(state == VALUE1){
				self->filename = strdup((const char *)event->data.scalar.value);
				state = KEY2;
			}else if(state == KEY2){
				if(!strcmp("Objects", (const char *)event->data.scalar.value))
					state = WAIT_SEQ;
			}
			break;
		default:
			break;
		}
		yaml_event_delete(event);
	}
}

/* need to load the model from the filename and regenerate all objects */
static void hkl3d_config_post_unserialize(struct Hkl3DConfig *self)
{
	int i;

	if(!self)
		return;

	self->context = g3d_context_new();

	/* first set the current directory using the directory parameter*/
	self->model = g3d_model_load_full(self->context, self->filename, NULL);
	for(i=0; i<self->len; ++i)
		hkl3d_object_post_unserialize(self->objects[i]);
}

/****************/
/* Hkl3DConfigs */
/****************/

static struct Hkl3DConfigs* hkl3d_configs_new(void)
{
	struct Hkl3DConfigs* self = NULL;

	self = (struct Hkl3DConfigs*)malloc(sizeof(struct Hkl3DConfigs));
	if(!self)
		return NULL;

	self->configs = NULL;
	self->len = 0;

	return self;
}

static void hkl3d_configs_free(struct Hkl3DConfigs *self)
{
	int i;

	if(!self)
		return;

	for(i=0; i<self->len; ++i)
		hkl3d_config_free(self->configs[i]);
	free(self->configs);
	free(self);
}

static struct Hkl3DConfig* hkl3d_configs_get_last(struct Hkl3DConfigs *self)
{
	return self->configs[self->len - 1];
}


static void hkl3d_configs_add_config(struct Hkl3DConfigs *self, struct Hkl3DConfig *config)
{
	config->configs = self;
	self->configs = (typeof(self->configs))realloc(self->configs, sizeof(*self->configs) * (self->len + 1));
	self->configs[self->len++] = config;
}

static void hkl3d_configs_delete_object(struct Hkl3DConfigs *self, struct Hkl3DObject *object)
{
	int i;

	for(i=0; i<self->len; ++i)
		hkl3d_config_delete_object(self->configs[i], object);
}

void hkl3d_configs_fprintf(FILE *f, const struct Hkl3DConfigs *self)
{
	int i;

	fprintf(f, "Hkl3DConfigs : %p\n", self);
	fprintf(f, "- configs (%d): %p\n", self->len, self->configs);
	for(i=0; i<self->len; ++i)
		hkl3d_config_fprintf(f, self->configs[i]);
}

static void hkl3d_configs_serialize(yaml_document_t *document, const struct Hkl3DConfigs *self)
{
	int i;
	int seq;

	if(!document || !self)
		return;

	/* Create the root of the config file */ 
	seq = yaml_document_add_sequence(document,
					 (yaml_char_t *)"coucou",
					 YAML_BLOCK_SEQUENCE_STYLE);
	for(i=0; i<self->len; i++){
		int node;

		node = hkl3d_config_serialize(document, self->configs[i]);
		yaml_document_append_sequence_item(document, seq, node);
	}
}

static void hkl3d_configs_unserialize(yaml_parser_t *parser, struct Hkl3DConfigs *self)
{
	yaml_event_t event;
	int done = 0;
	int in_seq = 0;
	int state;

	enum state {START, SEQ, DONE};

	state = START;
	while(state != DONE){
		yaml_parser_parse(parser, &event);
 
		/* first check for the end of the configs */
		switch(event.type){
		case YAML_STREAM_END_EVENT:
		case YAML_SEQUENCE_END_EVENT:
			state = DONE;
			break;
		}

		/* add the sequence */
		if ((state == SEQ)
		    && (event.type != YAML_SEQUENCE_END_EVENT)){
			Hkl3DConfig *config;

			config = hkl3d_config_new();
			hkl3d_config_unserialize(parser, &event, config);
			hkl3d_configs_add_config(self, config);
			yaml_event_delete(&event);
			continue;
		}

		switch(event.type){
		case YAML_SEQUENCE_START_EVENT:
			if(state == START)
				state = SEQ;
			break;
		default:
			break;
		}
		yaml_event_delete(&event);
	}
 }

static void hkl3d_configs_post_unserialize(struct Hkl3DConfigs *self)
{
	int i;
	for(i=0; i<self->len; ++i){
		hkl3d_config_post_unserialize(self->configs[i]);
	}
}

/**************/
/* Hkl3DStats */
/**************/

double hkl3d_stats_get_collision_ms(const struct Hkl3DStats *self)
{
	return self->collision.tv_sec*1000. + self->collision.tv_usec/1000.;
}

void hkl3d_stats_fprintf(FILE *f, const struct Hkl3DStats *self)
{
	fprintf(f, "transformation : %f ms collision : %f ms \n", 
		self->transformation.tv_sec*1000. + self->transformation.tv_usec/1000.,
		hkl3d_stats_get_collision_ms(self));
}

/*************/
/* Hkl3DAxis */
/*************/

static struct Hkl3DAxis *hkl3d_axis_new(void)
{
	struct Hkl3DAxis *self = NULL;

	self = HKL_MALLOC(Hkl3DAxis);

	self->objects = NULL; /* do not own the objects */
	self->len = 0;

	return self;
}

static void hkl3d_axis_free(struct Hkl3DAxis *self)
{
	if(!self)
		return;

	free(self->objects);
	free(self);
}

/* should be optimized (useless if the Hkl3DObject had a connection with the Hkl3DAxis */
static void hkl3d_axis_attach_object(struct Hkl3DAxis *self, struct Hkl3DObject *object)
{
	self->objects = (Hkl3DObject **)realloc(self->objects, sizeof(*self->objects) * (self->len + 1));
	self->objects[self->len++] = object;
}

/* should be optimized (useless if the Hkl3DObject had a connection with the Hkl3DAxis */
static void hkl3d_axis_detach_object(struct Hkl3DAxis *self, struct Hkl3DObject *object)
{
	int i;

	for(i=0; i<self->len; ++i)
		if(!hkl3d_object_cmp(self->objects[i], object)){
			self->len--;
			/* move all above objects of 1 position */
			if(i < self->len)
				memmove(&self->objects[i], &self->objects[i+1], sizeof(*self->objects) * (self->len - i));
		}
}

static void hkl3d_axis_fprintf(FILE *f, const struct Hkl3DAxis *self)
{
	int i;

	if(!f || !self)
		return;

	fprintf(f, "Hkl3DAxis : %p\n", self);
	fprintf(f, "- objects[");
	for(i=0; i<self->len; ++i)
		fprintf(f, " %d", self->objects[i]->id);
	fprintf(f, "] (%d) : %p :", self->len, self->objects);
	for(i=0; i<self->len; ++i)
		fprintf(f, " %p", self->objects[i]);
	fprintf(f, "\n");
}

/*****************/
/* Hkl3DGeometry */
/*****************/

static struct Hkl3DGeometry *hkl3d_geometry_new(int n)
{
	int i;
	struct Hkl3DGeometry *self = NULL;

	self = HKL_MALLOC(Hkl3DGeometry);

	self->axes = (Hkl3DAxis **)malloc(n * sizeof(*self->axes));
	self->len = n;

	for(i=0; i<n; ++i)
		self->axes[i] = hkl3d_axis_new();

	return self;	
}

static void hkl3d_geometry_free(struct Hkl3DGeometry *self)
{
	int i;

	if(!self)
		return;

	for(i=0; i<self->len; ++i)
		hkl3d_axis_free(self->axes[i]);
	free(self->axes);
	free(self);
}

static void hkl3d_geometry_fprintf(FILE *f, const struct Hkl3DGeometry *self)
{
	int i;

	if(!f || !self)
		return;

	fprintf(f, "HklGeometry : %p\n", self);
	fprintf(f, "- axes (%d) : %p\n", self->len, self->axes);
	for(i=0; i<self->len; ++i)
		hkl3d_axis_fprintf(f, self->axes[i]);
}

static void hkl3d_geometry_remove_object(struct Hkl3DGeometry *self, struct Hkl3DObject *object)
{
	int i;

	if(!self || !object)
		return;

	for(i=0; i<self->len; ++i)
		hkl3d_axis_detach_object(self->axes[i], object);
}

/*********/
/* HKL3D */
/*********/

static void hkl3d_apply_transformations(struct Hkl3D *self)
{
	int i;
	int k;
	struct timeval debut, fin;

	// set the right transformation of each objects and get numbers
	gettimeofday(&debut, NULL);
	for(i=0; i<self->geometry->holders_len; i++){
		size_t j;
		btQuaternion btQ(0, 0, 0, 1);

		size_t len = self->geometry->holders[i].config->len;
		for(j=0; j<len; j++){
			size_t k;
			size_t idx = self->geometry->holders[i].config->idx[j];
			HklAxis *axis = &self->geometry->axes[idx];
			G3DMatrix G3DM[16];
			
			// conversion beetween hkl -> bullet coordinates
			btQ *= btQuaternion(-axis->q.data[1],
					    axis->q.data[3],
					    axis->q.data[2],
					    axis->q.data[0]);

			// move each object connected to that hkl Axis.
			for(k=0; k<self->movingObjects->axes[idx]->len; ++k){
				self->movingObjects->axes[idx]->objects[k]->btObject->getWorldTransform().setRotation(btQ);
				self->movingObjects->axes[idx]->objects[k]->btObject->getWorldTransform().getOpenGLMatrix( G3DM );
				memcpy(self->movingObjects->axes[idx]->objects[k]->g3dObject->transformation->matrix, &G3DM[0], sizeof(G3DM));
			}

		}
	}
	gettimeofday(&fin, NULL);
	timersub(&fin, &debut, &self->stats.transformation);
}

/* dettach all objects from the bullet world */ 
static void hkl3d_clear_btworld(struct Hkl3D *self)
{
	if(!self)
		return;

	int i, j;

	/* remove all objects from the collision world */
	for(i=0; i<self->configs->len; ++i)
		for(j=0; j<self->configs->configs[i]->len; ++j)
			if(self->configs->configs[i]->objects[j]->added)
				self->_btWorld->removeCollisionObject(self->configs->configs[i]->objects[j]->btObject);
}

void hkl3d_connect_all_axes(struct Hkl3D *self)
{
	int i;
	int j;

	/* connect use the axes names */
	for(i=0;i<self->configs->len;i++)
		for(j=0;j<self->configs->configs[i]->len;j++)
			hkl3d_connect_object_to_axis(self,
						     self->configs->configs[i]->objects[j],
						     self->configs->configs[i]->objects[j]->axis_name);
}

/**
 * Hkl3D::Hkl3D:
 * @filename: 
 * @geometry: 
 *
 * 
 *
 * Returns: 
 **/
struct Hkl3D *hkl3d_new(const char *filename, HklGeometry *geometry)
{
	struct Hkl3D *self = NULL;

	self = HKL_MALLOC(Hkl3D);

	self->geometry = geometry;
	self->configs = hkl3d_configs_new();
	self->movingObjects = hkl3d_geometry_new(geometry->len);

	// first initialize the _movingObjects with the right len.
	self->_context = g3d_context_new();

	// initialize the bullet part
	self->_btCollisionConfiguration = new btDefaultCollisionConfiguration();

#ifdef USE_PARALLEL_DISPATCHER
	int maxNumOutstandingTasks = 2;
	PosixThreadSupport::ThreadConstructionInfo constructionInfo("collision",
								    processCollisionTask,
								    createCollisionLocalStoreMemory,
								    maxNumOutstandingTasks);
	self->_btThreadSupportInterface = new PosixThreadSupport(constructionInfo);
	self->_btDispatcher = new SpuGatheringCollisionDispatcher(self->_btThreadSupportInterface,
								  maxNumOutstandingTasks,
								  self->_btCollisionConfiguration);
#else
	self->_btDispatcher = new btCollisionDispatcher(self->_btCollisionConfiguration);
#endif
	btGImpactCollisionAlgorithm::registerAlgorithm(self->_btDispatcher);

	btVector3 worldAabbMin(-1000,-1000,-1000);
	btVector3 worldAabbMax( 1000, 1000, 1000);

	self->_btBroadphase = new btAxisSweep3(worldAabbMin, worldAabbMax);

	self->_btWorld = new btCollisionWorld(self->_btDispatcher,
					      self->_btBroadphase,
					      self->_btCollisionConfiguration);

	self->filename = filename;
	if (filename)
		hkl3d_load(self, filename);

	return self;
}

void hkl3d_free(struct Hkl3D *self)
{
	if(!self)
		return;

	hkl3d_clear_btworld(self);
	hkl3d_geometry_free(self->movingObjects);
	hkl3d_configs_free(self->configs);

	if (self->_btWorld)
		delete self->_btWorld;
	if (self->_btBroadphase)
		delete self->_btBroadphase;
	if (self->_btDispatcher)
		delete self->_btDispatcher;
#ifdef USE_PARALLEL_DISPATCHER
	if (self->_btThreadSupportInterface){
		//delete _btThreadSupportInterface;
		//_btThreadSupportInterface = 0;
	}
#endif
	if (self->_btCollisionConfiguration)
		delete self->_btCollisionConfiguration;
	g3d_context_free(self->_context);

	free(self);
}

struct Hkl3DConfig *hkl3d_add_model_from_file(struct Hkl3D *self,
					      const char *filename, const char *directory)
{	
	G3DModel * model;
	G3DObject *object;
	G3DMaterial *material;
	char current[PATH_MAX];
	struct Hkl3DConfig *config = NULL;
	int res;

	/* first set the current directory using the directory parameter*/
	getcwd(current, PATH_MAX);
	res = chdir(directory);
	model = g3d_model_load_full(self->_context, filename, 0);
	res = chdir(current);

	if(model){
		/* update the Hkl3D internals from the model */
		config = hkl3d_config_new_from_filename(filename, directory);
	}
	return config;
}

/* check that the axis name is really available in the Geometry */
/* if axis name not valid make the object static object->name = NULL */
/* ok so check if the axis was already connected  or not */
/* if already connected check if it was a different axis do the job */
/* if not yet connected do the job */
/* fill movingCollisionObject and movingG3DObjects vectors for transformations */
void hkl3d_connect_object_to_axis(struct Hkl3D *self,
				  struct Hkl3DObject *object, const char *name)
{
	bool update = false;
	bool connect = false;
	int idx = hkl_geometry_get_axis_idx_by_name(self->geometry, name);
	if (!object->movable){
		if(idx >= 0){ /* static -> movable */
			update = true;
			connect = true;
			object->movable = true;
		}
	}else{
		if(idx < 0){ /* movable -> static */
			object->movable = false;
			update = true;
			connect = false;
		}else{ /* movable -> movable */
			if(strcmp(object->axis_name, name)){ /* not the same axis */
				update = false;
				connect = true;
				int i = hkl_geometry_get_axis_idx_by_name(self->geometry, object->axis_name);
				struct Hkl3DObject **objects;

				for(int k=0;k<self->movingObjects->axes[i]->len;k++){
					objects = self->movingObjects->axes[i]->objects;
					if(!hkl3d_object_cmp(objects[k], object)){
						hkl3d_axis_detach_object(self->movingObjects->axes[i], object);
						break;	
					}		
				}
			}
		}
	}
	hkl3d_object_set_axis_name(object, name);
	if(update){
		/* first deconnected if already connected with a different axis */
		self->_btWorld->removeCollisionObject(object->btObject);
		delete object->btObject;
		delete object->btShape;
		object->btShape = shape_from_trimesh(object->meshes, object->movable);
		object->btObject = btObject_from_shape(object->btShape);
		// insert collision Object in collision world
		self->_btWorld->addCollisionObject(object->btObject);
		object->added = true;
	}
	if(connect)
		hkl3d_axis_attach_object(self->movingObjects->axes[idx], object);
}

/**
 * Hkl3D::hide_object:
 *
 * update the visibility of an Hkl3DObject in the bullet world
 * add or remove the object from the _btWorld depending on the hide
 * member of the object.
 **/
void hkl3d_hide_object(struct Hkl3D *self, struct Hkl3DObject *object, int hide)
{
	// first update the G3DObject
	object->hide = hide;
	object->g3dObject->hide = hide;
	if(object->hide){
		if (object->added){
			self->_btWorld->removeCollisionObject(object->btObject);
			object->added = false;
		}
	}else{
		if(!object->added){
			self->_btWorld->addCollisionObject(object->btObject);
			object->added = true;
		}
	}
}

/* remove an object from the model */
void hkl3d_remove_object(struct Hkl3D *self, struct Hkl3DObject *object)
{
	if(!self || !object)
		return;

	hkl3d_hide_object(self, object, TRUE);
	hkl3d_geometry_remove_object(self->movingObjects, object);

	/* now remove the G3DObject from the model */
	//self->model->objects = g_slist_remove(self->model->objects, object->g3dObject);
	g3d_object_free(object->g3dObject);
	hkl3d_configs_delete_object(self->configs, object);
}

/* use for the transparency of colliding objects */
struct ContactSensorCallback : public btCollisionWorld::ContactResultCallback
{
	ContactSensorCallback(struct Hkl3DObject *object)
		: btCollisionWorld::ContactResultCallback(),
		  collisionObject(object->btObject),
		  object(object)
		{ }
 
	btCollisionObject *collisionObject;
	struct Hkl3DObject *object;

	virtual btScalar addSingleResult(btManifoldPoint & cp,
					 const btCollisionObject *colObj0, int partId0, int index0,
					 const btCollisionObject *colObj1, int partId1, int index1)
		{
			if(colObj0 == collisionObject
			   || colObj1 == collisionObject)
				object->is_colliding = TRUE;
			return 0;
		}
};

int hkl3d_is_colliding(struct Hkl3D *self)
{
	int i;
	int j;
	bool res = true;
	int numManifolds;
	struct timeval debut, fin;

	//apply geometry transformation
	hkl3d_apply_transformations(self);
	// perform the collision detection and get numbers
	gettimeofday(&debut, NULL);
	if(self->_btWorld){
		self->_btWorld->performDiscreteCollisionDetection();
		self->_btWorld->updateAabbs();
	}
	gettimeofday(&fin, NULL);
	timersub(&fin, &debut, &self->stats.collision);
	
	numManifolds = self->_btWorld->getDispatcher()->getNumManifolds();

	/* reset all the collisions */
	for(i=0; i<self->configs->len; i++)
		for(j=0; j<self->configs->configs[i]->len; j++)
			self->configs->configs[i]->objects[j]->is_colliding = FALSE;

	/* check all the collisions */
	for(i=0; i<self->configs->len; i++)
		for(j=0; j<self->configs->configs[i]->len; j++){
			struct Hkl3DObject *object = self->configs->configs[i]->objects[j];
			ContactSensorCallback callback(object);
			self->_btWorld->contactTest(object->btObject, callback);
		}		

	return numManifolds != 0;
}

/**
 * Hkl3D::get_bounding_boxes:
 * @min: 
 * @max: 
 *
 * get the bounding boxes of the current world from the bullet internals.
 **/
void hkl3d_get_bounding_boxes(struct Hkl3D *self,
			      struct btVector3 *min, struct btVector3 *max)
{
	self->_btWorld->getBroadphase()->getBroadphaseAabb(*min, *max);
}

int hkl3d_get_nb_manifolds(struct Hkl3D *self)
{
	return self->_btDispatcher->getNumManifolds();
}

int hkl3d_get_nb_contacts(struct Hkl3D *self, int manifold)
{
	return self->_btDispatcher->getManifoldByIndexInternal(manifold)->getNumContacts();
}

void hkl3d_get_collision_coordinates(struct Hkl3D *self, int manifold, int contact,
				     double *xa, double *ya, double *za,
				     double *xb, double *yb, double *zb)
{
	btPersistentManifold *contactManifold;

	contactManifold = self->_btDispatcher->getManifoldByIndexInternal(manifold);
	btManifoldPoint & pt = contactManifold->getContactPoint(contact);
	btVector3 ptA = pt.getPositionWorldOnA();
	btVector3 ptB = pt.getPositionWorldOnB();

	*xa = ptA.x();
	*ya = ptA.y();
	*za = ptA.z();
	*xb = ptB.x();
	*yb = ptB.y();
	*zb = ptB.z();
}

void hkl3d_fprintf(FILE *f, const struct Hkl3D *self)
{
	fprintf(f, "Hkl3D : %p\n", self);
	fprintf(f, "- filename : %s\n", self->filename);
	hkl_geometry_fprintf(f, self->geometry);
	fprintf(f, "\n");
	hkl3d_stats_fprintf(f, &self->stats);
	hkl3d_configs_fprintf(f, self->configs);
	hkl3d_geometry_fprintf(f, self->movingObjects);

	fprintf(f, "- _len : %d\n", self->_len);
	fprintf(f, "- _context : %p\n", self->_context);
	fprintf(f, "- _btCollisionConfiguration : %p\n", self->_btCollisionConfiguration);
	fprintf(f, "- _btBroadphase : %p\n", self->_btBroadphase);
	fprintf(f, "- _btWorld : %p\n", self->_btWorld);
	fprintf(f, "- _btDispatcher : %p\n", self->_btDispatcher);
#ifdef USE_PARALLEL_DISPATCHER
	fprintf(f, "- _btThreadSupportInterface : %p\n", self->_btThreadSupportInterface);
#endif
}

void hkl3d_save(const struct Hkl3D *self, FILE *f)
{
	int i;
	yaml_emitter_t emitter;
	yaml_document_t document;

	if(!f || !self)
		return;

	memset(&emitter, 0, sizeof(emitter));
	memset(&document, 0, sizeof(document));
	
	if (!yaml_emitter_initialize(&emitter)) 
		fprintf(stderr, "Could not inialize the emitter object\n");
	yaml_emitter_set_output_file(&emitter, f);
	yaml_emitter_open(&emitter);
	
	/* Create an output_document object */
	if (!yaml_document_initialize(&document, NULL, NULL, NULL, 0, 0))
		fprintf(stderr, "Could not create a output_document object\n");

	hkl3d_configs_serialize(&document, self->configs);

	/* flush the document */
	yaml_emitter_dump(&emitter, &document);
	yaml_document_delete(&document);
	yaml_emitter_delete(&emitter);
}

/* regenerate the non serialized part */
static void hkl3d_post_unserialize(struct Hkl3D *self)
{
	char curdir[PATH_MAX];
	char *dirc;
	char *dir;

	/* set up the Geometry */
	hkl3d_geometry_free(self->movingObjects);
	self->movingObjects = hkl3d_geometry_new(self->geometry->len);

	/*
	 * compute the dirname of the config file as all model files
	 * will be relative to this directory
	 */
	getcwd(curdir, PATH_MAX);
	dirc = strdup(self->filename);
	dir = dirname(dirc);
	chdir(dir);

	hkl3d_configs_post_unserialize(self->configs);

	chdir(curdir);
	free(dirc);
 
	hkl3d_connect_all_axes(self);
}

void hkl3d_load(struct Hkl3D *self, const char *filename)
{
	int i, j;
	int state;
	yaml_parser_t parser;
	yaml_event_t event;
	FILE *file;
	struct Hkl3DConfigs *configs;

	enum state {START, DONE};

	/* Clear the objects. */
	memset(&parser, 0, sizeof(parser));
	memset(&event, 0, sizeof(event));

	file = fopen(filename, "rb");
	if (!file){
		fprintf(stderr, "Could not open the %s config file\n", filename);
		return;
	}

	if (!yaml_parser_initialize(&parser))
		fprintf(stderr, "Could not initialize the parser object\n");
	yaml_parser_set_input_file(&parser, file);

	state = START;
	while(state != DONE){
		/* Get the next event. */
		yaml_parser_parse(&parser, &event);

		switch(event.type){
			/* Check if this is the stream end. */
		case YAML_STREAM_END_EVENT:
		case YAML_DOCUMENT_END_EVENT:
			state = DONE;
			break;
		case YAML_DOCUMENT_START_EVENT:
			configs = hkl3d_configs_new();
			hkl3d_configs_unserialize(&parser, configs);
			/* put a reference to hkl3d in the configs */
			hkl3d_clear_btworld(self);
			hkl3d_configs_free(self->configs);
			self->configs = configs;
			state = DONE;
			break;
		default:
			break;
		}
		yaml_event_delete(&event);
	}

   	yaml_parser_delete(&parser);
	fclose(file);

	self->filename = filename;

	hkl3d_post_unserialize(self);

	hkl3d_fprintf(stdout, self);
}

