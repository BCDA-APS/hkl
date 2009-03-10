#include <stdlib.h>
#include <string.h>

#include <hkl/hkl-parameter.h>

HklParameter *hkl_parameter_new(char const *name,
				double min, double value, double max,
				int not_to_fit, int changed,
				HklUnit const *unit, HklUnit const *punit)
{
	HklParameter *parameter;

	parameter = malloc(sizeof(*parameter));
	if (!parameter)
		die("Cannot allocate memory for an HklParameter");

	if (hkl_parameter_init(parameter,
			       name, min, value, max,
			       not_to_fit, changed,
			       unit, punit)) {
		free(parameter);
		parameter = NULL;
	}

	return parameter;
}

HklParameter *hkl_parameter_new_copy(HklParameter const *self)
{
	HklParameter *parameter = NULL;

	parameter = malloc(sizeof(*parameter));
	if (!parameter)
		die("Cannot allocate memory for an HklParameter");

	*parameter = *self;

	return parameter;
}

int hkl_parameter_init(HklParameter *self, char const *name,
		       double min, double value, double max,
		       int not_to_fit, int changed,
		       HklUnit const *unit, HklUnit const *punit)
{
	if (min <= value
	    && value <= max
	    && strcmp(name, "")
	    && hkl_unit_compatible(unit, punit)) {
		self->name = name;
		self->range.min = min;
		self->range.max = max;
		self->value = value;
		self->unit = unit;
		self->punit = punit;
		self->not_to_fit = not_to_fit;
		self->changed = changed;
	} else
		return HKL_FAIL;

	return HKL_SUCCESS;
}

void hkl_parameter_free(HklParameter *self)
{
	free(self);
}

void hkl_parameter_set_value(HklParameter *self, double value)
{
	self->value = value;
	self->changed = HKL_TRUE;
}

/* TODO test */
double hkl_parameter_get_value_unit(HklParameter const *self)
{
	double factor = hkl_unit_factor(self->unit, self->punit);

	return self->value * factor;
}

/* TODO test */
int hkl_parameter_set_value_unit(HklParameter *self, double value)
{
	double factor = hkl_unit_factor(self->unit, self->punit);

	self->value = value / factor;
	self->changed = HKL_TRUE;

	return HKL_SUCCESS;
}

void hkl_parameter_randomize(HklParameter *self)
{
	if (!self->not_to_fit) {
		double alea = (double)rand() / (RAND_MAX + 1.);
		self->value = self->range.min
			+ (self->range.max - self->range.min) * alea;
		self->changed = HKL_TRUE;
	}
}

void hkl_parameter_fprintf(FILE *f, HklParameter *self)
{
	double factor = hkl_unit_factor(self->unit, self->punit);
	if (self->punit)
		fprintf(f, "\"%s\" : %f %s [%f : %f]",
			self->name,
			self->value * factor,
			self->punit->repr,
			self->range.min * factor,
			self->range.max * factor);
	else
		fprintf(f, "\"%s\" : %f [%f : %f]",
			self->name,
			self->value * factor,
			self->range.min * factor,
			self->range.max * factor);
}
