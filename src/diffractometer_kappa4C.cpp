#include "diffractometer_kappa4C.h"
#include "pseudoaxe_kappa4C.h"
#include "mode_kappa4C.h"

namespace hkl {
    namespace diffractometer {
        namespace kappa4C {

            Vertical::Vertical(void) : Diffractometer<geometry::kappa4C::Vertical>()
            {
              // On met � jour le nom.
              set_name("Vertical Kappa 4 Circles Generic Soleil");

              set_description("This diffractometer was design by Fr�d�ric-emmanuel PICCA\n\
                              * modes: .\n\
                              * pseudoAxes: .");

              // On ajouta les modes.
              m_modeList.add(new mode::kappa4C::vertical::eulerian4C::Bissector);
              m_modeList.add(new mode::kappa4C::vertical::eulerian4C::Delta_Theta);
              m_modeList.add(new mode::kappa4C::vertical::eulerian4C::Constant_Omega);
              m_modeList.add(new mode::kappa4C::vertical::eulerian4C::Constant_Chi);
              m_modeList.add(new mode::kappa4C::vertical::eulerian4C::Constant_Phi);

              // On ajoute les pseudoAxes
              m_pseudoAxeList.add(new pseudoAxe::kappa4C::vertical::Omega);
              m_pseudoAxeList.add(new pseudoAxe::kappa4C::vertical::Chi);
              m_pseudoAxeList.add(new pseudoAxe::kappa4C::vertical::Phi);
              m_pseudoAxeList.add(new pseudoAxe::kappa4C::vertical::eulerian4C::Psi);
              m_pseudoAxeList.add(new pseudoAxe::kappa4C::vertical::twoC::Th2th);
              m_pseudoAxeList.add(new pseudoAxe::kappa4C::vertical::twoC::Q2th);
              m_pseudoAxeList.add(new pseudoAxe::kappa4C::vertical::twoC::Q);
            }

            Vertical::~Vertical(void)
              {
                // On supprime les modes.
                m_modeList.free();

                // On supprime les pseudoAxes.
                m_pseudoAxeList.free();
              }

        } // namespace kappa4C
    } // namespace diffractometer
} // namespace hkl
