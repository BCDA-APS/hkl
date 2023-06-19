#ifndef __XRAYS_DROPLET_H__
#define __XRAYS_DROPLET_H__

#include <stdlib.h>
#include "xrays-image.h"

XRAYS_BEGIN_DECLS

typedef struct _XRaysDroplet XRaysDroplet;

struct _XRaysDroplet
{
	unsigned int nb_gouttes;
	float I_max;
	float I_tot;
	int I_traitement;

	XRaysImage const *dark;
	XRaysImage *gtt;
	XRaysImage *indic;
	XRaysImage *img;
	short int trigger;
	short int seuil;
	short int ADU_per_photon;
	int cosmic;
	int hist;
	int contour;
	int nb_images;
	int nb_pixels;
	XRaysImage *histogram;
};

/*
 * Allocate the memory for the Gtt structure of data_size
 */
extern XRaysDroplet* xrays_droplet_new(XRaysImage const *dark, double trigger, double seuil, double ADU_per_photon, int cosmic, int contour);

/*
 * destroy the Gtt structure
 */
extern void xrays_droplet_free(XRaysDroplet *droplet);

/*
 * Cette fonction rempli le tableau gtt pour un niveau de trigger donn�. Le
 * principe est simplement de remplir par le bas le tableau avec les
 * indice_ui32s des pixels appartenant aux diff�rentes gouttes. On les s�pare
 * en multipliant l'indice_ui32 du dernier pixel par -1. On a ainsi un
 * enchainement de gouttes s�epar�es par un indice_ui32 n�gatif.
 * On fait de m�me avec les contours correspondant mais cette fois-ci par
 * le haut du tableau.
 * Lors de la recherche des gouttes et des contours, on utilise le tableau
 * indic qui a les m�mes dimensions que l'image � traiter et qui indique si
 * un pixel appartient d�j� � une goutte, ou s'il s'agit d'un contour, � combien 
 * de gouttes voisines il appartient.
 */
extern int xrays_droplet_add_images(XRaysDroplet *droplet, XRaysImage const *img);

extern void xrays_droplet_reset(XRaysDroplet *droplet);

XRAYS_END_DECLS

#endif
