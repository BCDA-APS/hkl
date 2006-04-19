#include "diffractometer_eulerian4C.h"
#include "pseudoaxe_eulerian4C.h"
#include "geometry_eulerian4C.h"
#include "mode_eulerian4C.h"

namespace hkl {
  namespace diffractometer {

    Eulerian4C::Eulerian4C(void) : Diffractometer()
    {
      // On met � jour le nom.
      set_name("Eulerian 4C Generic Soleil");

      set_description("This diffractometer was design by Fr�d�ric-emmanuel PICCA\n\
                       * modes: bissector, delta theta, constant omega, constant chi, constant phi.\n\
                       * pseudoAxes: Psi.");

      // On s'occupe de d�finir les axes de rotation du diffractom�tre.
      m_geometry = new geometry::eulerian4C::Vertical;
      
      // On met � jour la liste des modes utilisables.
      m_modeList.add(new mode::eulerian4C::vertical::Bissector);
      m_modeList.add(new mode::eulerian4C::vertical::Delta_Theta);
      m_modeList.add(new mode::eulerian4C::vertical::Constant_Omega);
      m_modeList.add(new mode::eulerian4C::vertical::Constant_Chi);
      m_modeList.add(new mode::eulerian4C::vertical::Constant_Phi);

      // On ajoute les pseudoAxes
      m_pseudoAxeList.add(new pseudoAxe::eulerian4C::vertical::Psi);
    }

    Eulerian4C::~Eulerian4C(void)
    {
      // On supprime la geometrie.
      delete m_geometry;

      // On supprime les modes.
      m_modeList.free();
      // On supprime les pseudoAxes.
      m_pseudoAxeList.free();
    }

  } // namespace diffractometer
} // namespace hkl
