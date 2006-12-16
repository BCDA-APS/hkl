#ifndef _DIFFRACTOMETER_EULERIAN6C_H_
#define _DIFFRACTOMETER_EULERIAN6C_H_

#include "diffractometer.h"
#include "geometry_eulerian6C.h"

/**
 * \page Diffractometer_eulerian_6C Diffractometer Eulerian 6C.
 *
 * \section geometrie Geometrie
 *
 * Nous allons nous inspirer du mod�le de You pour notre diffractom�tre (fig. [cap:4S+2D]) ici pr�sent� tous
 * les angles mis � z�ro.
 * Les rayons-X arrivent suivant le vecteur \f$ \vec{x} \f$ (le rep�re est diff�rent de celui de You).
 *
 * \section pseudomoteurs Pseudomoteurs
 *
 * Le principe des calcules de You est d'exprimer dans le rep�re du laboratoire le vecteur diffusion \f$ \vec{Q} \f$
 * de deux fa�ons diff�rentes.
 * Une premi�re en utilisant les angles du goniom�tre 4S puis une � partir des angles du d�tecteur 2D et de la connaissance
 * des coordonn�es du vecteur incident.
 * En �galant les deux expressions, il obtient un syst�me d'�quation � 6 inconnus mais seulement 3 �quations.
 * Pour �tre � m�me de r�soudre le syst�me il faut fixer des contraintes suppl�mentaire.
 * C'est ce que l'on appel les modes de fonctionnement du diffractom�tre.
 * Il est commode de d�finir d'autres angles que ceux du diffractom�tre relativement � des vecteurs
 * caract�ristiques tel que le vecteur de diffusion \f$ \vec{Q} \f$  ou un vecteur pointant dans une direction particuli�re du cristal \f$ \vec{n} \f$.
 * Cette direction peut-�tre soit li� � la cristallographie du cristal soit � sa forme (une normale � une face).
 * La figure [cap:Pseudo-Angles-li�s] repr�sente les angles li�s au vecteur de diffusion et � ce vecteur de r�f�rence.
 * Tout d'abord  \f$ \theta \f$ (angle entre \f$ \vec{Q} \f$ et le plan  yz) et qui correspond � l'angle de Bragg.
 * \f$ \vartheta \f$ qui est l'angle azimutal que fait la projection de \f$ \vec{Q} \f$ sur le plan \a yz et la direction  \a +y (fig [cap:Pseudo-Angles-li�s]a).
 * Il y a ensuite les angles  \f$ \alpha \f$ et \f$ \varphi \f$ d�finits comme pr�c�demment mais pour le vecteur
 * de r�f�rence \f$ \vec{n} \f$ (fig [cap:Pseudo-Angles-li�s]b).
 * Et finalement les angles \f$ \tau \f$ (angle entDiffractometer_re \f$ \vec{Q} \f$ et \f$ \vec{n} \f$) et \f$ \psi \f$ qui
 * correspond � la rotation de \f$ \vec{n} \f$ autour du vecteur de diffusion \f$ \vec{Q} \f$ (fig [cap:Pseudo-Angles-li�s]c).
 * L'origine de cet angle \f$ \psi \f$ est prise � z�ro lorsque le vecteur \f$ \vec{n} \f$ est dans le plan de
 * diffraction (plan contenant \f$ \vec{Q} \f$ et \f$ \vec{k_{i}} \f$) (fig [cap:Pseudo-Angles-li�s]d).
 * Il est alors possible d'exprimer ces pseudos angles en fonction des angles physique du diffractom�tre.
 */

namespace hkl
{
namespace diffractometer
{

/**
 * The eulerian 6-circle diffractometer as described in 
 * H. You "Angle calculations for a `4S+2D' six-circle diffractometer" (1999)
 * <A HREF="http://journals.iucr.org/index.html"> J. Appl. Cryst.</A>, <B>32</B>, 614-623.
 * Two circles have been added from a 4C diffractometer, MU for the crystal and NU formula
 * the detector. According to H. You conventions the circle previously called Omega
 * has been renamed Eta and the detector circle called 2Theta has been renamed Delta.
 */
class Eulerian6C : public DiffractometerTemp<geometry::Eulerian6C>
{
public:

    /**
     * @brief Default constructor
     * @return A new diffractometer
     */
    Eulerian6C(void);

    /**
     * @brief Destructor
     *
     * Destructor
     */
    virtual ~Eulerian6C(void);
};

} // namespace diffractometer
} // namespace hkl

#endif // _DIFFRACTOMETER_EULERIAN6C_H_
