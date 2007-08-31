#ifndef _KAPPA4C_VERTICAL_DIFFRACTOMETER_H
#define _KAPPA4C_VERTICAL_DIFFRACTOMETER_H


#include "diffractometer.h"
#include "kappa4C_vertical_pseudoaxeengine.h"
#include "kappa4C_vertical_mode.h"
#include "kappa4C_vertical_geometry.h"

namespace hkl {

namespace kappa4C {

namespace vertical {

/**
 * @page Diffractometer_kappa_4C Diffractometer kappa 4 Circles.
 * 
 * @section Geometry_K4C Geometry.
 * 
 * Nous allons nous inspirer du mod�le de Busin et Levy pour d�crire notre diffractom�tre.
 * Les sens de rotation sont respect�s mais le rep�re directe est choisi de fa�on � correspondre
 * au rep�re de laboratoire de la ligne CRYSTAL du synchrotron Soleil.
 * Les photons-X se propagent suivant le vecteur @f$\vec{x}@f$ et la direction verticale est suivant
 * le vecteur @f$\vec{z}@f$.
 * Ce diffractom�tre est de type verticale (le vecteur de diffusion @f$\vec{Q}@f$ est dans le plan \a xOz).
 * Les axes permettant de d�crire la configuration du diffractom�tre sont les suivants:
 *  - �chantillon
 *    - "komega"
 *    - "kappa"
 *    - "kphi"
 *  - D�tecteur
 *    - "tth"
 * 
 * @section pseudoaxes_K4C Pseudo-axes
 * 
 * Il est int�ressant de piloter un diffractom�tre kappa de la m�me fa�on qu'un diffractom�tre eul�rien.
 * Nous allons donc pr�senter ces pseudo-axes.
 * 
 * @subsection pseudoaxes_K4C_eulerian Eul�riens
 * 
 * Pour trouver les relations math�matiques liant ces pseudo-axes aux axes kappa
 * nous alors utiliser les quaternions li�s aux diff�rents axes des diffractom�tres.
 *  - Kappa.
 *  
 * @f{align*}
 *    && q_{\omega_\kappa} && = &&\cos\frac{\omega_\kappa}{2} && + && 0\times i && + && -\sin\frac{\omega_\kappa}{2} \times j && + && 0\times k && \\
 *    && q_\kappa && = && \cos\frac{\kappa}{2} && + && 0\times i && + && -\sin\frac{\kappa}{2}\cos\alpha \times j && + && -\sin\frac{\kappa}{2}\sin\alpha \times k &&\\
 *    && q_{\phi_\kappa} && = && \cos\frac{\phi_\kappa}{2} && + && 0\times i && + && -\sin\frac{\phi_\kappa}{2} \times j && + && 0 \times k &&
 * @f}
 *  - Eulerien.
 *  
 * @f{align*}
 *    && q_\omega && = &&\cos\frac{\omega}{2} && + && 0\times i && + && -\sin\frac{\omega}{2} \times j && + && 0\times k && \\
 *    && q_\chi && = && \cos\frac{\chi}{2} && + && \sin\frac{\chi}{2}\times i && + && 0 \times j && + && 0 \times k &&\\
 *    && q_\phi && = && \cos\frac{\phi}{2} && + && 0\times i && + && -\sin\frac{\phi}{2} \times j && + && 0 \times k &&
 * @f}
 * 
 * On veut que:
 * @f[
 *  q_\omega q_\chi q_\phi = q_{\omega_\kappa} q_\kappa q_{\phi_\kappa} 
 * @f]
 * 
 * Cela revient � r�soudre le syst�me suivant:
 * @f{align}
 *  \cos\frac{\chi}{2} \cos\left(\frac{\omega}{2} + \frac{\phi}{2}\right)
 *    & = & \cos\frac{\kappa}{2} \cos\left(\frac{\omega_\kappa}{2} + \frac{\phi_\kappa}{2}\right) - \sin\frac{\kappa}{2} \cos\alpha \sin\left(\frac{\omega_\kappa}{2} + \frac{\phi_\kappa}{2}\right) \\
 *  \sin\frac{\chi}{2} \cos\left(\frac{\omega}{2} - \frac{\phi}{2}\right)
 *    & = & \sin\frac{\kappa}{2} \sin\alpha \sin\left(\frac{\omega_\kappa}{2} - \frac{\phi_\kappa}{2}\right) \\
 *  -\cos\frac{\chi}{2} \sin\left(\frac{\omega}{2} + \frac{\phi}{2}\right)
 *    & = & -\cos\frac{\kappa}{2} \sin\left(\frac{\omega_\kappa}{2} + \frac{\phi_\kappa}{2}\right) - \sin\frac{\kappa}{2} \cos\alpha \cos\left(\frac{\omega_\kappa}{2} + \frac{\phi_\kappa}{2}\right) \\
 *  \sin\frac{\chi}{2} \sin\left(\frac{\omega}{2} - \frac{\phi}{2}\right)
 *    & = & -\sin\frac{\kappa}{2} \sin\alpha \cos\left(\frac{\omega_\kappa}{2} - \frac{\phi_\kappa}{2}\right)
 * @f}
 * 
 * @subsubsection pseudoaxes_K4C_eulerian2kappa Eul�rien vers kappa.
 * 
 * On trouve deux solutions.
 * @f{align*}
 *  \omega_\kappa & = \omega + \arcsin\left(\frac{\tan\frac{\chi}{2}}{\tan\alpha}\right) - \frac{\pi}{2} 
 *    && \mbox{}
 *    & \omega_\kappa & = \omega - \arcsin\left(\frac{\tan\frac{\chi}{2}}{\tan\alpha}\right) + \frac{\pi}{2} \\
 *  \kappa & = -2 \arcsin\left(\frac{\sin\frac{\chi}{2}}{\sin\alpha}\right)
 *    && ou
 *    & \kappa & = 2 \arcsin\left(\frac{\sin\frac{\chi}{2}}{\sin\alpha}\right)\\
 *  \phi_\kappa & = \phi + \arcsin\left(\frac{\tan\frac{\chi}{2}}{\tan\alpha}\right) + \frac{\pi}{2}
 *    && \mbox{}
 *    & \phi_\kappa & = \phi - \arcsin\left(\frac{\tan\frac{\chi}{2}}{\tan\alpha}\right) - \frac{\pi}{2}\\
 * @f}
 * 
 * @subsubsection pseudoaxes_K4C_kappa2eulerian Kappa vers Eul�rien.
 * 
 * On � de la m�me fa�on deux solutions.
 * @f{align*}
 *  \omega & = \omega_\kappa + \arctan\left( \tan\frac{\kappa}{2} \cos\alpha \right) + \frac{\pi}{2} 
 *    &&
 *    & \omega & = \omega_\kappa + \arctan\left( \tan\frac{\kappa}{2} \cos\alpha \right) - \frac{\pi}{2} \\
 *  \chi & = -2 \arcsin\left( \sin\frac{\kappa}{2} \sin\alpha \right)
 *    && ou
 *    & \chi & = 2 \arcsin\left( \sin\frac{\kappa}{2} \sin\alpha \right)\\
 *  \phi & = \phi_\kappa + \arctan\left( \tan\frac{\kappa}{2} \cos\alpha \right) - \frac{\pi}{2}
 *    &&
 *    & \phi & = \phi_\kappa - \arcsin\left( \tan\frac{\kappa}{2} \cos\alpha \right) + \frac{\pi}{2}\\
 * @f}
 */
class Diffractometer : public hkl::DiffractometerTemp<hkl::kappa4C::vertical::Geometry> {
  public:
    Diffractometer(double alpha);

    virtual ~Diffractometer();

};

} // namespace hkl::kappa4C::vertical

} // namespace hkl::kappa4C

} // namespace hkl
#endif
