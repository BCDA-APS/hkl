--------------------------------- Projet HKL -------------------------------------------
-- librairie permettant le calcul des angles moteurs d'un diffractom�tre en fonction  --
-- des coordonn�es de l'espace r�ciproque du cristal.                                 --
----------------------------------------------------------------------------------------

- compil� (statique) avec MS VC6 (Makefile.VC, d�pend des options de compil tango (cf
fichier tango.opt par exemple)) et gcc 3.2.2 (Makefile).
- diffractom�tre 4 cercles : mode bisecteur.
- diffractom�tre 6 cercles : modes 4 cercles horizontal et vertical.

- TODO :
pour le 6 cercles, mode 3 cercles bras levant.
pour le 4 cercles, mode omega constant (pb d'architecture : variable omega).

- projets li�s :
Tango Device Server "DiffractometerEulerian4Circles".
Syst�me de pilotage d'un diffractom�tre 4 cercles au Laboratoire de Physique du Solide.
