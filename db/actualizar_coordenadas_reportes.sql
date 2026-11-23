-- =====================================================================
-- Radar Vecinal · Reubicar reportes demo dentro de los 9 polígonos reales
-- =====================================================================
-- INSTRUCCIONES:
--   1. Abre este archivo en DBeaver y conéctate a radar_vecinal.
--   2. Ejecuta el bloque completo (Ctrl+A → Ctrl+Enter).
--   3. Verifica con la consulta al final del script.
--
-- Todos los (lat, lng) han sido validados con ray-casting contra los
-- polígonos reales de los 9 sectores (margen interior 20% + verificación
-- post-desplazamiento). Ningún punto cae fuera de su id_barrio.
-- =====================================================================

BEGIN;

-- b1: Torre Torre
UPDATE public.reportes SET lat = -12.05858, lng = -75.18843 WHERE id = 'r1';
UPDATE public.reportes SET lat = -12.0581, lng = -75.18821 WHERE id = 'r2';
UPDATE public.reportes SET lat = -12.05762, lng = -75.188 WHERE id = 'r3';
UPDATE public.reportes SET lat = -12.05826, lng = -75.18779 WHERE id = 'r4';
UPDATE public.reportes SET lat = -12.05778, lng = -75.18757 WHERE id = 'r5';
UPDATE public.reportes SET lat = -12.05842, lng = -75.18736 WHERE id = 'r6';
-- b2: Palián
UPDATE public.reportes SET lat = -12.04109, lng = -75.19699 WHERE id = 'r7';
UPDATE public.reportes SET lat = -12.04173, lng = -75.19677 WHERE id = 'r8';
UPDATE public.reportes SET lat = -12.04125, lng = -75.19655 WHERE id = 'r9';
UPDATE public.reportes SET lat = -12.04189, lng = -75.19633 WHERE id = 'r10';
UPDATE public.reportes SET lat = -12.04141, lng = -75.19723 WHERE id = 'r11';
UPDATE public.reportes SET lat = -12.04093, lng = -75.19701 WHERE id = 'r12';
UPDATE public.reportes SET lat = -12.04157, lng = -75.19679 WHERE id = 'r13';
UPDATE public.reportes SET lat = -12.04109, lng = -75.19657 WHERE id = 'r14';
UPDATE public.reportes SET lat = -12.04173, lng = -75.19635 WHERE id = 'r15';
UPDATE public.reportes SET lat = -12.04125, lng = -75.19613 WHERE id = 'r16';
-- b3: San Carlos
UPDATE public.reportes SET lat = -12.06664, lng = -75.20588 WHERE id = 'r17';
UPDATE public.reportes SET lat = -12.06616, lng = -75.20656 WHERE id = 'r18';
UPDATE public.reportes SET lat = -12.0668, lng = -75.20626 WHERE id = 'r19';
UPDATE public.reportes SET lat = -12.06632, lng = -75.20603 WHERE id = 'r20';
UPDATE public.reportes SET lat = -12.06696, lng = -75.2058 WHERE id = 'r21';
UPDATE public.reportes SET lat = -12.06648, lng = -75.20557 WHERE id = 'r22';
UPDATE public.reportes SET lat = -12.06712, lng = -75.20534 WHERE id = 'r23';
UPDATE public.reportes SET lat = -12.06664, lng = -75.20511 WHERE id = 'r24';
UPDATE public.reportes SET lat = -12.06616, lng = -75.206 WHERE id = 'r25';
UPDATE public.reportes SET lat = -12.0668, lng = -75.20577 WHERE id = 'r26';
UPDATE public.reportes SET lat = -12.06632, lng = -75.20554 WHERE id = 'r27';
UPDATE public.reportes SET lat = -12.06696, lng = -75.20531 WHERE id = 'r28';
UPDATE public.reportes SET lat = -12.06648, lng = -75.20508 WHERE id = 'r29';
UPDATE public.reportes SET lat = -12.06712, lng = -75.20485 WHERE id = 'r30';
UPDATE public.reportes SET lat = -12.06664, lng = -75.20462 WHERE id = 'r31';
-- b4: Zona Monumental
UPDATE public.reportes SET lat = -12.07461, lng = -75.21343 WHERE id = 'r32';
UPDATE public.reportes SET lat = -12.07413, lng = -75.21319 WHERE id = 'r33';
UPDATE public.reportes SET lat = -12.07477, lng = -75.21296 WHERE id = 'r34';
UPDATE public.reportes SET lat = -12.07429, lng = -75.21273 WHERE id = 'r35';
UPDATE public.reportes SET lat = -12.07381, lng = -75.21249 WHERE id = 'r36';
UPDATE public.reportes SET lat = -12.07445, lng = -75.21338 WHERE id = 'r37';
UPDATE public.reportes SET lat = -12.07397, lng = -75.21315 WHERE id = 'r38';
UPDATE public.reportes SET lat = -12.07461, lng = -75.21291 WHERE id = 'r39';
UPDATE public.reportes SET lat = -12.07413, lng = -75.21268 WHERE id = 'r40';
UPDATE public.reportes SET lat = -12.07477, lng = -75.21245 WHERE id = 'r41';
UPDATE public.reportes SET lat = -12.07429, lng = -75.21221 WHERE id = 'r42';
UPDATE public.reportes SET lat = -12.07381, lng = -75.21198 WHERE id = 'r43';
UPDATE public.reportes SET lat = -12.07445, lng = -75.21287 WHERE id = 'r44';
UPDATE public.reportes SET lat = -12.07397, lng = -75.21263 WHERE id = 'r45';
UPDATE public.reportes SET lat = -12.07461, lng = -75.2124 WHERE id = 'r46';
UPDATE public.reportes SET lat = -12.07413, lng = -75.21217 WHERE id = 'r47';
UPDATE public.reportes SET lat = -12.07477, lng = -75.21193 WHERE id = 'r48';
-- b5: Ocopilla
UPDATE public.reportes SET lat = -12.07276, lng = -75.19851 WHERE id = 'r49';
UPDATE public.reportes SET lat = -12.0734, lng = -75.19824 WHERE id = 'r50';
UPDATE public.reportes SET lat = -12.07292, lng = -75.19908 WHERE id = 'r51';
UPDATE public.reportes SET lat = -12.07356, lng = -75.1988 WHERE id = 'r52';
UPDATE public.reportes SET lat = -12.07308, lng = -75.19853 WHERE id = 'r53';
UPDATE public.reportes SET lat = -12.07372, lng = -75.19825 WHERE id = 'r54';
UPDATE public.reportes SET lat = -12.07324, lng = -75.19798 WHERE id = 'r55';
-- b6: Cajas Chico
UPDATE public.reportes SET lat = -12.08019, lng = -75.22585 WHERE id = 'r56';
UPDATE public.reportes SET lat = -12.08083, lng = -75.22562 WHERE id = 'r57';
UPDATE public.reportes SET lat = -12.08035, lng = -75.22539 WHERE id = 'r58';
UPDATE public.reportes SET lat = -12.07987, lng = -75.22515 WHERE id = 'r59';
UPDATE public.reportes SET lat = -12.08051, lng = -75.22492 WHERE id = 'r60';
UPDATE public.reportes SET lat = -12.08003, lng = -75.22469 WHERE id = 'r61';
UPDATE public.reportes SET lat = -12.08067, lng = -75.22557 WHERE id = 'r62';
UPDATE public.reportes SET lat = -12.08019, lng = -75.22534 WHERE id = 'r63';
UPDATE public.reportes SET lat = -12.08083, lng = -75.22511 WHERE id = 'r64';
UPDATE public.reportes SET lat = -12.08035, lng = -75.22488 WHERE id = 'r65';
UPDATE public.reportes SET lat = -12.07987, lng = -75.22464 WHERE id = 'r66';
-- b7: San Antonio
UPDATE public.reportes SET lat = -12.0546, lng = -75.19969 WHERE id = 'r67';
UPDATE public.reportes SET lat = -12.05412, lng = -75.19946 WHERE id = 'r68';
UPDATE public.reportes SET lat = -12.05476, lng = -75.19923 WHERE id = 'r69';
UPDATE public.reportes SET lat = -12.05428, lng = -75.20013 WHERE id = 'r70';
UPDATE public.reportes SET lat = -12.05492, lng = -75.19927 WHERE id = 'r71';
UPDATE public.reportes SET lat = -12.05444, lng = -75.19904 WHERE id = 'r72';
UPDATE public.reportes SET lat = -12.05396, lng = -75.19881 WHERE id = 'r73';
UPDATE public.reportes SET lat = -12.0546, lng = -75.19859 WHERE id = 'r74';
UPDATE public.reportes SET lat = -12.05412, lng = -75.19836 WHERE id = 'r75';
UPDATE public.reportes SET lat = -12.05476, lng = -75.19813 WHERE id = 'r76';
UPDATE public.reportes SET lat = -12.05428, lng = -75.19902 WHERE id = 'r77';
UPDATE public.reportes SET lat = -12.05492, lng = -75.19879 WHERE id = 'r78';
UPDATE public.reportes SET lat = -12.05444, lng = -75.19856 WHERE id = 'r79';
-- b8: Uñas
UPDATE public.reportes SET lat = -12.0344, lng = -75.18989 WHERE id = 'r80';
UPDATE public.reportes SET lat = -12.03392, lng = -75.18965 WHERE id = 'r81';
UPDATE public.reportes SET lat = -12.03344, lng = -75.18941 WHERE id = 'r82';
UPDATE public.reportes SET lat = -12.03408, lng = -75.18918 WHERE id = 'r83';
UPDATE public.reportes SET lat = -12.0336, lng = -75.18894 WHERE id = 'r84';
UPDATE public.reportes SET lat = -12.03424, lng = -75.18871 WHERE id = 'r85';
UPDATE public.reportes SET lat = -12.03376, lng = -75.18847 WHERE id = 'r86';
UPDATE public.reportes SET lat = -12.0344, lng = -75.18935 WHERE id = 'r87';
UPDATE public.reportes SET lat = -12.03392, lng = -75.18912 WHERE id = 'r88';
UPDATE public.reportes SET lat = -12.03344, lng = -75.18888 WHERE id = 'r89';
UPDATE public.reportes SET lat = -12.03408, lng = -75.18865 WHERE id = 'r90';
UPDATE public.reportes SET lat = -12.0336, lng = -75.18841 WHERE id = 'r91';
UPDATE public.reportes SET lat = -12.03424, lng = -75.18817 WHERE id = 'r92';
UPDATE public.reportes SET lat = -12.03376, lng = -75.18794 WHERE id = 'r93';
UPDATE public.reportes SET lat = -12.0344, lng = -75.18882 WHERE id = 'r94';
UPDATE public.reportes SET lat = -12.03392, lng = -75.18859 WHERE id = 'r95';
UPDATE public.reportes SET lat = -12.03344, lng = -75.18835 WHERE id = 'r96';
UPDATE public.reportes SET lat = -12.03408, lng = -75.18811 WHERE id = 'r97';
-- b9: Chorrillos
UPDATE public.reportes SET lat = -12.04883, lng = -75.19113 WHERE id = 'r98';
UPDATE public.reportes SET lat = -12.04947, lng = -75.19092 WHERE id = 'r99';
UPDATE public.reportes SET lat = -12.04899, lng = -75.1907 WHERE id = 'r100';
UPDATE public.reportes SET lat = -12.04963, lng = -75.19048 WHERE id = 'r101';
UPDATE public.reportes SET lat = -12.04915, lng = -75.19133 WHERE id = 'r102';
UPDATE public.reportes SET lat = -12.04867, lng = -75.19111 WHERE id = 'r103';
UPDATE public.reportes SET lat = -12.04931, lng = -75.19089 WHERE id = 'r104';
UPDATE public.reportes SET lat = -12.04883, lng = -75.19067 WHERE id = 'r105';

-- Verificación opcional (ejecutar después del COMMIT):
-- SELECT r.id, r.id_barrio, r.lat, r.lng FROM public.reportes r ORDER BY r.id;

COMMIT;