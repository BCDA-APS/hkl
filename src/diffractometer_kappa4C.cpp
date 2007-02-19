#include "diffractometer_kappa4C.h"
#include "pseudoaxeengine_kappa4C.h"
#include "mode_kappa4C.h"

namespace hkl
  {
  namespace diffractometer
    {
    namespace kappa4C
      {

      Vertical::Vertical(double alpha) :
          DiffractometerTemp<geometry::kappa4C::Vertical>("Vertical Kappa 4 Circles Generic Soleil",
              "This diffractometer was design by Fr�d�ric-emmanuel PICCA\n\
              * modes: .\n\
              * pseudoAxes: .")
      {
        // On ajouta les modes.
        _modes.add( new mode::kappa4C::vertical::eulerian4C::Bissector("Bissector", "Omega = 2theta / 2. \n there is no parameters for this mode.", _geom_T) );
        _modes.add( new mode::kappa4C::vertical::eulerian4C::Delta_Theta("Delta Theta", "Omega = theta + dtheta.", _geom_T) );
        _modes.add( new mode::kappa4C::vertical::eulerian4C::Constant_Omega("Constant Omega", "Omega = Constante.", _geom_T) );
        _modes.add( new mode::kappa4C::vertical::eulerian4C::Constant_Chi("Constant Chi", "chi = Constante.", _geom_T) );
        _modes.add( new mode::kappa4C::vertical::eulerian4C::Constant_Phi("Constant Phi", "phi = Constante.", _geom_T) );

        _pseudoAxeEngines.push_back( new pseudoAxeEngine::kappa4C::vertical::Eulerians(_geom_T) );
        _pseudoAxeEngines.push_back( new pseudoAxeEngine::kappa4C::vertical::Th2th(_geom_T) );
        _pseudoAxeEngines.push_back( new pseudoAxeEngine::kappa4C::vertical::Q2th(_geom_T) );
        _pseudoAxeEngines.push_back( new pseudoAxeEngine::kappa4C::vertical::Q(_geom_T) );
        _pseudoAxeEngines.push_back( new pseudoAxeEngine::kappa4C::vertical::Psi(_geom_T) );
      }

      Vertical::~Vertical(void)
      {
        // On supprime les modes.
        _modes.clear();

        // On supprime les pseudoAxes.
        _pseudoAxeEngines.clear();
      }

    } // namespace kappa4C
  } // namespace diffractometer
} // namespace hkl
