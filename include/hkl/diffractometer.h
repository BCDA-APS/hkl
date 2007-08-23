#ifndef _DIFFRACTOMETER_H
#define _DIFFRACTOMETER_H


#include "hklobject.h"
#include "geometry.h"
#include "samplelist.h"
#include "modelist.h"
#include "pseudoaxeenginelist.h"
#include "affinementlist.h"
#include <string>
#include "pseudoaxelist.h"
#include <ostream>
#include <istream>

namespace hkl {

/**
 *
 * \mainpage
 *
 * L'objectif de cette librairie est de m�tre � disposition l'ensemble des outils permettant de piloter
 * un diffractom�tre. L'ensemble des calcules pr�sents dans cette librairie sont bas�s sur une �quation
 * fondamentale.
 *
 * @ref Diffractometer
 * 
 * @ref Diffractometer_eulerian_4C
 *
 * @ref Diffractometer_eulerian_6C
 *
 * @ref Diffractometer_kappa_4C
 */

/**
 * @page Diffractometer G�n�ralit�.
 *
 * \section Equation_fondamentales Equations fondamentales
 * 
 * Le probl�me que nous devons r�soudre est de calculer pour une famille de plan (h,k,l) donn�,
 * les angles de rotation du diffractom�tre qui permettent de le mettre en condition de diffraction.
 * Il faut donc exprimer les relations math�matiques qui lient les diff�rents angles entre eux lorsque
 * la condition de Bragg est v�rifi�e. L'�quation fondamentale est la suivante:
 * \f[
 *    \left( \prod_i S_i \right) \cdot U \cdot B \cdot \vec{h} = \left( \prod_i D_i - I \right)
 * \f]
 * \f[
 *    R \cdot U \cdot B \cdot \vec{h} = \vec{Q}
 * \f]
 * o� \f$ \vec{h} \f$ est le vecteur (h,k,l) , \f$ \vec{k_i} \f$ est le vecteur incident,  \f$ S_i \f$ les
 * matrices de rotations des mouvements li�s � l'�chantillon, \f$ D_j \f$  les matrices de rotation
 * des mouvements li�s au d�tecteur,
 * \a I  la matrice identit�, \a U  la matrice d'orientation du cristal par rapport au rep�re de l'axe
 * sur lequel ce dernier est mont� et \a B  la matrice de passage d'un rep�re non orthonorm�
 * (celui du crystal r�ciproque) � un rep�re orthonorm�. 
 * 
 * L'�quation fondamentale nous permet d'�crire:
 * \f[
 *    U \cdot B \cdot \vec{h} = \tilde{R} \cdot \vec{Q}.
 * \f]
 * 
 * Cette �quation est de 4 ou 6 inconnues pour seulement 3 �quations.
 * Il faut donc imposer des contraintes pour r�soudre ce syst�me et ainsi orienter le diffractom�tre.
 * Ces diff�rentes contraintes d�finissent les modes de fonctionnement des diffractom�tres.
 * 
 * \section Calcule_de_B Calcule de B.
 *
 * Si l'on conna�t les param�tres cristallins du cristal �tudi�, il est tr�s simple de calculer
 * cette matrice \a B :
 * \f[ 
 *    B=\left(
 *        \begin{matrix}
 *          a^{*} & b^{*}\cos\gamma^{*} & c^{*}\cos\beta^{*} \\
 *              0 & b^{*}\sin\gamma^{*} & -c^{*} \sin\beta^{*} \cos\alpha \\
 *              0 &                   0 & 1/c
 *        \end{matrix}
 *      \right)
 * \f]
 * 
 * Le calcule de \f$ a^\star \f$, \f$ b^\star \f$ et \f$ c^\star \f$
 * est obtenu de la fa�on suivante:
 * \f{eqnarray*}
 *    a^\star & = & \tau \frac{\sin\alpha}{aD} \\
 *    b^\star & = & \tau \frac{\sin\beta}{bD} \\
 *    c^\star & = & \tau \frac{\sin\gamma}{cD}
 * \f}
 * 
 * ou
 *
 * \f[
 *    D = \sqrt{1 - \cos^2\alpha - \cos^2\beta - \cos^2\gamma + 2\cos\alpha \cos\beta \cos\gamma}
 * \f]
 * 
 * pour obtenir les angles \f$ \alpha^\star \f$, \f$ \beta^\star \f$ et \f$ \gamma^\star \f$,
 * on passe par le calcule des sinus et cosinus.
 * \f[
 *  \begin{array}{cc}
 *    \cos\alpha^\star = \frac{\cos\beta \cos\gamma - \cos\alpha}{\sin\beta \sin\gamma} 
 *      & \sin\alpha^\star = \frac{D}{\sin\beta \sin\gamma} \\
 *    \cos\beta^\star = \frac{\cos\gamma \cos\alpha - \cos\beta}{\sin\gamma \sin\alpha} 
 *      & \sin\beta^\star = \frac{D}{\sin\gamma \sin\alpha} \\
 *    \cos\gamma^\star = \frac{\cos\alpha \cos\beta - \cos\gamma}{\sin\alpha \sin\beta} 
 *      & \sin\gamma^\star = \frac{D}{\sin\alpha \sin\beta} \\
 *  \end{array}
 * \f]
 *
 * \section Calcule_de_U Calcule de U.
 *
 * Il existe plusieurs fa�ons de calculer \a U. Busing et Levy en a propos� plusieurs.
 * Nous allons pr�senter celle qui n�cessite la mesure de seulement deux r�flections ainsi que la
 * connaissance des param�tres cristallins.
 * Cette fa�on de calculer la matrice d'orientation \a U, peut �tre g�n�ralis�e � n'importe quel
 * diffractom�tre pour peu que la description des axes de rotation permette d'obtenir la matrice
 * de rotation de la machine \a R et le vecteur de diffusion \f$ \vec{Q} \f$.
 * Il est �galement possible de calculer \a U sans la conna�ssance des param�tres cristallins.
 * il faut alors faire un affinement des param�tres. Cela revient � minimiser une fonction.
 * Nous allons utiliser la m�thode du simplex pour trouver ce minimum et ainsi ajuster l'ensemble
 * des param�tres cristallins ainsi que la matrice d'orientation.
 * 
 * \subsection Algorithme_de_Busing_Levy Algorithme de Busing Levy.
 *
 * L'id�e est de se placer dans le rep�re de l'axe sur lequel est mont� l'�chantillon.
 * On mesure deux r�flections \f$ (\vec{h}_1, \vec{h}_2) \f$ ainsi que leurs angles associ�s.
 * Cela nous permet de calculer \a R et \f$ \vec{Q} \f$ pour chacune de ces reflections.
 * Nous avons alors ce syst�me:
 * \f[
 *    U \cdot B \cdot \vec{h}_1
 * \f]
 * De fa�on � calculer facilement \a U, il est int�ressant de d�finir deux tri�dres orthonorm�
 * \f$ T_{\vec{h}} \f$ et \f$ T_{\vec{Q}} \f$ � partir des vecteurs \f$ (B \cdot \vec{h}_1, B \cdot \vec{h}_2) \f$
 * et \f$ (\tilde{R}_1 \cdot \vec{Q}_1, \tilde{R}_2 \cdot \vec{Q}_2) \f$.
 * On a alors tr�s simplement:
 * \f[
 *    U \cdot T_{\vec{h}} = T_{\vec{Q}}
 * \f]
 * Et donc:
 * \f[
 *    U = T_{\vec{Q}} \cdot \tilde{T}_{\vec{h}}
 * \f]
 *
 * \subsection Affinement_par_la_methode_du_simplex Affinement par la m�thode du simplex
 *
 * Dans ce cas nous ne connaissons pas la matrice \a B, il faut alors mesurer plus de
 * deux r�flections afin d'ajuster les 9 param�tres.
 * Six param�tres pour le crystal et trois pour la matrice d'orientation \a U.
 * Les trois param�tres qui permennt de representer \a U sont en fait les angles d'euler.
 * Il est donc n�cessaire de connaitre la repr�sentation Eul�rien de la matrice \a U et r�ciproquement.
 * \f[
 *    U = X \cdot Y \cdot Z
 * \f]
 * o� \a X est la matrice rotation suivant l'axe Ox et le premier angle d'Euler,
 * \a Y la matrice de rotation suivant l'axe Oy et le deuxi�me angle d'Euler et \a Z la matrice du troisi�me
 * angle d'Euler pour l'axe Oz.
 * \f[
 *      \left(
 *        \begin{matrix}
 *          1 & 0 & 0\\
 *          0 & A & -B\\
 *          0 & B & A
 *        \end{matrix}
 *      \right)
 *      \left(
 *        \begin{matrix}
 *          C & 0 & D\\
 *          0 & 1 & 0\\
 *         -D & 0 & C
 *        \end{matrix}
 *      \right)
 *      \left(
 *        \begin{matrix}
 *          E & -F & 0\\
 *          F & E & 0\\
 *          0 & 0 & 1
 *        \end{matrix}
 *      \right)
 * \f]
 * 
 * et donc:
 * 
 * \f[ 
 *    U = \left(
 *          \begin{matrix}
 *                CE &     -CF & D \\
 *            BDE+AF & -BDF+AE & -BC \\
 *           -ADE+BF &  ADF+BE & AC
 *          \end{matrix}
 *        \right)
 *  \f]
 */
class Diffractometer : public hkl::HKLObject {
  protected:
    hkl::Geometry * _geometry;

    hkl::SampleList * _samples;

    hkl::ModeList _modes;

    hkl::PseudoAxeEngineList _pseudoAxeEngines;

    hkl::AffinementList _affinements;


  public:
    Diffractometer(const std::string & name, const std::string & description);

    virtual ~Diffractometer();

    inline hkl::Geometry * geometry();

    inline hkl::SampleList & samples();

    inline hkl::ModeList & modes();

    /**
     * @brief Return the PseudoAxeList of the Diffractometer.
     * @return The PseudoAxeList of the Diffractometer.
     */
    
    inline hkl::PseudoAxeList & pseudoAxes();

    inline hkl::AffinementList & affinements();

    /**
     * \brief Are two Diffractometer equals ?
     * \param diffractometer the Diffractometer to compare with.
     * \return true if both are equals false otherwise.
     */
    bool operator==(const Diffractometer & diffractometer) const;

    /**
     * @brief print the Diffractometer into a flux
     * @param flux The stream to print into.
     * @return The modified flux.
     */
    std::ostream & printToStream(std::ostream & flux) const;

    /**
     * @brief print on a stream the content of the Diffractometer
     * @param flux the ostream to modify.
     * @return the modified ostream
     */
    std::ostream & toStream(std::ostream & flux) const;

    /**
     * @brief restore the content of the Diffractometer from an istream
     * @param flux the istream.
     * @return the modified istream.
     * @todo problem of security here.
     */
    std::istream & fromStream(std::istream & flux);

};
inline hkl::Geometry * Diffractometer::geometry() 
{
  return _geometry;
}

inline hkl::SampleList & Diffractometer::samples() 
{
  return *_samples;
}

inline hkl::ModeList & Diffractometer::modes() 
{
  return _modes;
}

/**
 * @brief Return the PseudoAxeList of the Diffractometer.
 * @return The PseudoAxeList of the Diffractometer.
 */

inline hkl::PseudoAxeList & Diffractometer::pseudoAxes() 
{
  // Bouml preserved body begin 00037582
      return _pseudoAxeEngines.pseudoAxes();
  // Bouml preserved body end 00037582
}

inline hkl::AffinementList & Diffractometer::affinements() 
{
  return _affinements;
}

template<class T>
class DiffractometerTemp : public hkl::Diffractometer {
  protected:
    T * _geom_T;


  public:
    DiffractometerTemp(const std::string & name, const std::string & description);

    DiffractometerTemp(const std::string & name, const std::string & description, double alpha);

    virtual ~DiffractometerTemp();

};
template<class T>
DiffractometerTemp<T>::DiffractometerTemp(const std::string & name, const std::string & description) :
  hkl::Diffractometer(name, description) 
{
  // Bouml preserved body begin 00037882
      _geom_T = new T;
      _geometry = _geom_T;
      _samples = new SampleList(*_geom_T);
  // Bouml preserved body end 00037882
}

template<class T>
DiffractometerTemp<T>::DiffractometerTemp(const std::string & name, const std::string & description, double alpha) :
  hkl::Diffractometer(name, description) 
{
  // Bouml preserved body begin 0003E202
      _geom_T = new T(alpha);
      _geometry = _geom_T;
      _samples = new SampleList(*_geom_T);
  // Bouml preserved body end 0003E202
}

template<class T>
DiffractometerTemp<T>::~DiffractometerTemp() 
{
  // Bouml preserved body begin 00037902
      delete _geom_T;
      delete _samples;
  // Bouml preserved body end 00037902
}


} // namespace hkl
inline std::ostream &
operator << (std::ostream & flux, hkl::Diffractometer const & diffractometer)
{
  return diffractometer.printToStream(flux);
}

#endif
