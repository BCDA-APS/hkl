#ifndef _DIFFRACTOMETER_H_
#define _DIFFRACTOMETER_H_

#include "geometry.h"
#include "samplelist.h"
#include "modelist.h"
#include "pseudoaxeenginelist.h"
#include "affinementlist.h"

using namespace std;

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

namespace hkl
  {

  class Diffractometer : public HKLObject
    {
    public:

      /**
       * @brief The default destructor
       */
      virtual ~Diffractometer(void);

      /**
       * @brief compare two diffractometer
       * @param diffractometer The Diffractometer to compare with.
       * @return true if both are equals.
       */
      bool operator ==(Diffractometer const & diffractometer) const;

      ostream & printToStream(ostream & flux) const;
      ostream & toStream(ostream & flux) const;
      istream & fromStream(istream & flux);

      /**
       * @brief Get a pointer on the diffractometer Geometry.
       * @return The Geometry.
       */
      Geometry * geometry(void)
      {
        return _geometry;
      }

      /**
       * @brief Return the ModeList of the diffractometer.
       * @return the ModeList of the diffractometer.
       */
      ModeList & modes(void)
      {
        return _modes;
      }

      /**
       * @brief Return a pointer on the SampleList of the diffractometer.
       * @return The SampleList of the diffractometer.
       */
      SampleList * samples(void)
      {
        return _samples;
      }

      /**
       * @brief Return the PseudoAxeList of the diffractometer.
       * @return The PseudoAxeList of the diffractometer.
       */
      PseudoAxeList & pseudoAxes(void)
      {
        return _pseudoAxeEngines.pseudoAxes();
      }

      /**
       * @brief Return the AffinementList of the diffractometer.
       * @return the AffinementList of the diffractometer.
       */
      AffinementList & affinements(void)
      {
        return _affinements;
      }

    protected:
      Geometry * _geometry; //!< The current diffractometer Geometry.
      SampleList * _samples; //!< The SampleList of the diffractometers.
      ModeList _modes; //!< The available modes.
      PseudoAxeEngineList _pseudoAxeEngines; //!< The available PseudoAxes.
      AffinementList _affinements; //!< the available Affinement.

      /**
       * @brief The Default constructor -- protected to be sure that Diffractometer is an abstract class.
       * @param name The name of the Diffractometer.
       * @param description The description of the Diffractometer.
       */
      Diffractometer(MyString const & name, MyString const & description);
    };


  template<typename T>
  class DiffractometerTemp : public Diffractometer
    {
    public:

      /**
       * @brief The default destructor.
       */
      virtual ~DiffractometerTemp(void)
      {
        delete _samples;
      }

    protected:
      T  _geom_T; //!< The current diffractometer Geometry.

      /**
       * @brief the defaul constructor
       * @param name The DiffractometerTemp name.
       * @param description the DiffractometerTemp description.
       */
      DiffractometerTemp(MyString const & name, MyString const & description) :
          Diffractometer(name, description)
      {
        _geometry = &_geom_T;
        _samples = new SampleList(_geom_T);
      }
    };

} // namespace hkl

inline std::ostream &
operator << (std::ostream & flux, hkl::Diffractometer const & diffractometer)
{
  return diffractometer.printToStream(flux);
}

#endif // _DIFFRACTOMETER_H_
