#ifndef _DIFFRACTOMETER_TWOC_H
#define _DIFFRACTOMETER_TWOC_H

#include "diffractometer.h"
#include "geometry_twoC.h"

/**
 *  \page Diffractometer_2C Diffractometer 2C.
 *
 *  \section geometrie Geometrie
 *
 * Ce diffractometre est un diffractom�tre deux cercles.
 * Les sens de rotation sont respect�s mais le rep�re directe est choisi de fa�on � correspondre
 * au rep�re de laboratoire de la ligne CRYSTAL du synchrotron Soleil.
 * Les photons-X se propagent suivant le vecteur \f$ \vec{x} \f$ et la direction verticale est suivant
 * le vecteur \f$ \vec{z} \f$.
 * Ce diffractom�tre est de type verticale (le vecteur de diffusion \f$ \vec{Q} \f$ est dans le plan \a xOz).
 * Les angles permettant de d�crire la configuration du diffractom�tre sont pr�sent�s sur la figure.
 *
 * \section pseudomotors Pseudo-moteurs
 *
 * \section modes Modes
 *
 * \subsection Symetric Symetric
 *
 * Dans ce mode on choisit d'avoir :
 * 
 * \f{eqnarray*}
 *    \mbox{"omega"} & = & \theta \\
 *    \mbox{"2theta"} & = & 2\theta
 * \f]
 * 
 * \subsection Fix_Incidence Fix Incidence
 *
 * Ce mode consiste � laisser \f$ \omega \f$ libre et � ne bouger que \f$ 2\theta \f$ :
 * "2theta" = \f$2\theta\f$
 */

namespace hkl
  {
  namespace diffractometer
    {
    namespace twoC
      {

      /**
       * The eulerian 4-circle diffractometer.
       * William R. Busing and Henri A. Levy "Angle calculation for 3- and 4- Circle X-ray and  Neutron Diffractometer" (1967)
       * <A HREF="http://journals.iucr.org/index.html"> Acta Cryst.</A>, <B>22</B>, 457-464.
       */
      class Vertical : public DiffractometerTemp<geometry::twoC::Vertical>
        {
        public:
          /**
           * @brief Default constructor.
           * @return a new diffractometer_Eulerian4C diffractometer.
           *
           * Default constructor.
           */
          Vertical(void);

          /**
           * @brief Destructor
           *
           * Destructor
           */
          virtual ~Vertical(void);
        };

    } // namepsace twoC
  } // namespace diffractometer
} // namespace hkl

#endif // _DIFFRACTOMETER_TWOC_H
