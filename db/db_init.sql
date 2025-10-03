/* ===========================================================
    CuidemJunts - MariaDB (IDs + Datos Extensos)
   =========================================================== */

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

/* ---------- DROPS (orden seguro) ---------- */
DROP TABLE IF EXISTS `alerta`;
DROP TABLE IF EXISTS `cita`;
DROP TABLE IF EXISTS `comunicacion`;
DROP TABLE IF EXISTS `usuario_contacto`;
DROP TABLE IF EXISTS `usuario`;
DROP TABLE IF EXISTS `supervisor`;
DROP TABLE IF EXISTS `teleoperador`;
DROP TABLE IF EXISTS `trabajador`;

/* ===========================================================
    1) CREATE TABLES (todas con ID)
   =========================================================== */

/* trabajador (superclase) */
CREATE TABLE `trabajador` (
  `id_trab` INT NOT NULL AUTO_INCREMENT,
  `dni` CHAR(9) NOT NULL,
  `nombre` VARCHAR(100) NOT NULL,
  `telefono` VARCHAR(20) NOT NULL,
  `usuario` VARCHAR(50) NOT NULL,
  `contrasena` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id_trab`),
  UNIQUE KEY `uq_trabajador_usuario` (`usuario`),
  UNIQUE KEY `uq_trabajador_dni` (`dni`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* teleoperador (1:1 con trabajador) */
CREATE TABLE `teleoperador` (
  `id_teleoperador` INT NOT NULL AUTO_INCREMENT,
  `id_trab` INT NOT NULL,
  PRIMARY KEY (`id_teleoperador`),
  UNIQUE KEY `uq_teleoperador_trab` (`id_trab`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* supervisor (1:1 con trabajador) — incluye DNI pero NO es PK */
CREATE TABLE `supervisor` (
  `id_supervisor` INT NOT NULL AUTO_INCREMENT,
  `id_trab` INT NOT NULL,
  `dni` CHAR(9) NOT NULL,
  PRIMARY KEY (`id_supervisor`),
  UNIQUE KEY `uq_supervisor_trab` (`id_trab`),
  UNIQUE KEY `uq_supervisor_dni` (`dni`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* usuario (cada usuario lo gestiona un teleoperador) */
CREATE TABLE `usuario` (
  `id_persona` INT NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(100) NOT NULL,
  `apellido` VARCHAR(100) NOT NULL,
  `telefono` VARCHAR(20) NOT NULL,
  `id_teleoperador` INT NOT NULL,
  PRIMARY KEY (`id_persona`),
  KEY `idx_usuario_teleoperador` (`id_teleoperador`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* usuario_contacto (recursiva) — con ID propio */
CREATE TABLE `usuario_contacto` (
  `id_usuario_contacto` BIGINT NOT NULL AUTO_INCREMENT,
  `id_usuario` INT NOT NULL,
  `id_contacto` INT NOT NULL,
  PRIMARY KEY (`id_usuario_contacto`),
  UNIQUE KEY `uq_usuario_contacto_pair` (`id_usuario`, `id_contacto`),
  KEY `idx_contacto` (`id_contacto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* cita (pertenece a un teleoperador) */
CREATE TABLE `cita` (
  `id_cita` INT NOT NULL AUTO_INCREMENT,
  `fecha` DATE NOT NULL,
  `hora_inicio` TIME NOT NULL,
  `id_teleoperador` INT NOT NULL,
  PRIMARY KEY (`id_cita`),
  KEY `idx_cita_teleoperador` (`id_teleoperador`),
  KEY `idx_cita_fecha` (`fecha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* alerta (generada por una cita) */
CREATE TABLE `alerta` (
  `id_alerta` INT NOT NULL AUTO_INCREMENT,
  `id_cita` INT NOT NULL,
  `tipo` ENUM('recordatorio','incidencia','urgente') NOT NULL DEFAULT 'recordatorio',
  `descripcion` VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (`id_alerta`),
  KEY `idx_alerta_cita` (`id_cita`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* comunicacion (supervisada por un supervisor) */
CREATE TABLE `comunicacion` (
  `id_comunicacion` INT NOT NULL AUTO_INCREMENT,
  `id_supervisor` INT NOT NULL,
  `fecha` DATE NOT NULL,
  `hora_inicio` TIME NOT NULL,
  `hora_fin` TIME NOT NULL,
  `observaciones` TEXT,
  PRIMARY KEY (`id_comunicacion`),
  KEY `idx_com_supervisor` (`id_supervisor`),
  KEY `idx_com_fecha` (`fecha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

/* ===========================================================
    2) FOREIGN KEYS
   =========================================================== */

ALTER TABLE `teleoperador`
  ADD CONSTRAINT `fk_teleoperador_trabajador`
  FOREIGN KEY (`id_trab`) REFERENCES `trabajador` (`id_trab`)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `supervisor`
  ADD CONSTRAINT `fk_supervisor_trabajador`
  FOREIGN KEY (`id_trab`) REFERENCES `trabajador` (`id_trab`)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `usuario`
  ADD CONSTRAINT `fk_usuario_teleoperador`
  FOREIGN KEY (`id_teleoperador`) REFERENCES `teleoperador` (`id_teleoperador`)
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `usuario_contacto`
  ADD CONSTRAINT `fk_usuario_contacto_usuario`
  FOREIGN KEY (`id_usuario`) REFERENCES `usuario` (`id_persona`)
  ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_usuario_contacto_contacto`
  FOREIGN KEY (`id_contacto`) REFERENCES `usuario` (`id_persona`)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `cita`
  ADD CONSTRAINT `fk_cita_teleoperador`
  FOREIGN KEY (`id_teleoperador`) REFERENCES `teleoperador` (`id_teleoperador`)
  ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE `alerta`
  ADD CONSTRAINT `fk_alerta_cita`
  FOREIGN KEY (`id_cita`) REFERENCES `cita` (`id_cita`)
  ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `comunicacion`
  ADD CONSTRAINT `fk_comunicacion_supervisor`
  FOREIGN KEY (`id_supervisor`) REFERENCES `supervisor` (`id_supervisor`)
  ON DELETE RESTRICT ON UPDATE CASCADE;

/* ===========================================================
    3) DUMMIES (Datos extensos y coherentes)
   =========================================================== */

START TRANSACTION;

/* --- Trabajadores (12) --- */
INSERT INTO `trabajador` (dni, nombre, telefono, usuario, contrasena) VALUES
('11111111A','Carlos Pérez','600111111','cperez','pass123'),
('22222222B','Ana Torres','600222222','atorres','pass123'),
('33333333C','Luis Gómez','600333333','lgomez','pass123'),
('44444444D','Marta Ruiz','600444444','mruiz','pass123'),
('55555555E','Sergio López','600555555','slopez','pass123'),
('66666666F','Elena Ramos','600666666','eramos','pass123'),
('77777777G','Javier Díaz','600777777','jdiaz','pass123'),
('88888888H','Patricia León','600888888','pleon','pass123'),
('99999999J','Diego Martín','600999999','dmartin','pass123'),
('12345678Z','Sara Pérez','601111111','sperez','pass123'),
('23456789Y','Hugo Romero','602222222','hromero','pass123'),
('34567890X','Nuria Vidal','603333333','nvidal','pass123');

/* --- Teleoperadores (7) — 1:1 con algunos trabajadores --- */
SET @T_CP := (SELECT id_trab FROM trabajador WHERE usuario='cperez');
SET @T_AT := (SELECT id_trab FROM trabajador WHERE usuario='atorres');
SET @T_MR := (SELECT id_trab FROM trabajador WHERE usuario='mruiz');
SET @T_SL := (SELECT id_trab FROM trabajador WHERE usuario='slopez');
SET @T_ER := (SELECT id_trab FROM trabajador WHERE usuario='eramos');
SET @T_DM := (SELECT id_trab FROM trabajador WHERE usuario='dmartin');
SET @T_SP := (SELECT id_trab FROM trabajador WHERE usuario='sperez');

INSERT INTO `teleoperador` (id_trab) VALUES
(@T_CP),(@T_AT),(@T_MR),(@T_SL),(@T_ER),(@T_DM),(@T_SP);

/* Guardamos IDs de teleoperador para FKs en usuarios/citas */
SET @TEL_CP := (SELECT id_teleoperador FROM teleoperador t WHERE t.id_trab=@T_CP);
SET @TEL_AT := (SELECT id_teleoperador FROM teleoperador t WHERE t.id_trab=@T_AT);
SET @TEL_MR := (SELECT id_teleoperador FROM teleoperador t WHERE t.id_trab=@T_MR);
SET @TEL_SL := (SELECT id_teleoperador FROM teleoperador t WHERE t.id_trab=@T_SL);
SET @TEL_ER := (SELECT id_teleoperador FROM teleoperador t WHERE t.id_trab=@T_ER);
SET @TEL_DM := (SELECT id_teleoperador FROM teleoperador t WHERE t.id_trab=@T_DM);
SET @TEL_SP := (SELECT id_teleoperador FROM teleoperador t WHERE t.id_trab=@T_SP);

/* --- Supervisores (5) — con DNI propio NO PK --- */
SET @S_LG := (SELECT id_trab FROM trabajador WHERE usuario='lgomez');
SET @S_JD := (SELECT id_trab FROM trabajador WHERE usuario='jdiaz');
SET @S_PL := (SELECT id_trab FROM trabajador WHERE usuario='pleon');
SET @S_HR := (SELECT id_trab FROM trabajador WHERE usuario='hromero');
SET @S_NV := (SELECT id_trab FROM trabajador WHERE usuario='nvidal');

INSERT INTO `supervisor` (id_trab, dni) VALUES
(@S_LG, (SELECT dni FROM trabajador WHERE id_trab=@S_LG)),
(@S_JD, (SELECT dni FROM trabajador WHERE id_trab=@S_JD)),
(@S_PL, (SELECT dni FROM trabajador WHERE id_trab=@S_PL)),
(@S_HR, (SELECT dni FROM trabajador WHERE id_trab=@S_HR)),
(@S_NV, (SELECT dni FROM trabajador WHERE id_trab=@S_NV));

/* Guardamos IDs de supervisor para comunicaciones */
SET @SUP_LG := (SELECT id_supervisor FROM supervisor s WHERE s.id_trab=@S_LG);
SET @SUP_JD := (SELECT id_supervisor FROM supervisor s WHERE s.id_trab=@S_JD);
SET @SUP_PL := (SELECT id_supervisor FROM supervisor s WHERE s.id_trab=@S_PL);
SET @SUP_HR := (SELECT id_supervisor FROM supervisor s WHERE s.id_trab=@S_HR);
SET @SUP_NV := (SELECT id_supervisor FROM supervisor s WHERE s.id_trab=@S_NV);

/* --- Usuarios (24) — distribuidos entre teleoperadores --- */
INSERT INTO `usuario` (nombre, apellido, telefono, id_teleoperador) VALUES
('María','López','611111111',@TEL_CP),
('Pedro','Martínez','622222222',@TEL_CP),
('Lucía','García','633333333',@TEL_AT),
('Sofía','Hernández','644444444',@TEL_AT),
('David','Santos','655555555',@TEL_MR),
('Laura','Ramírez','666666666',@TEL_MR),
('Antonio','Morales','677777777',@TEL_SL),
('Paula','Gómez','688888888',@TEL_SL),
('Cristina','Vega','699999999',@TEL_ER),
('José','Navarro','610000000',@TEL_ER),
('Elena','Castro','611222333',@TEL_DM),
('Raúl','Prieto','612333444',@TEL_DM),
('Clara','Ortega','613444555',@TEL_SP),
('Iván','Serrano','614555666',@TEL_SP),
('Noa','Rey','615666777',@TEL_CP),
('Héctor','Molina','616777888',@TEL_AT),
('Marta','Navas','617888999',@TEL_MR),
('Julia','Iglesias','618999000',@TEL_SL),
('Gonzalo','Pascual','619000111',@TEL_ER),
('Alicia','Cuesta','620111222',@TEL_DM),
('Irene','Campos','621222333',@TEL_SP),
('Pablo','Gil','622333444',@TEL_CP),
('Adriana','Delgado','623444555',@TEL_AT),
('Samuel','Luna','624555666',@TEL_MR);

/* IDs de usuarios para contactos */
SET @U1 := 1;  SET @U2 := 2;  SET @U3 := 3;  SET @U4 := 4;  SET @U5 := 5;  SET @U6 := 6;
SET @U7 := 7;  SET @U8 := 8;  SET @U9 := 9;  SET @U10:=10;  SET @U11:=11;  SET @U12:=12;
SET @U13:=13;  SET @U14:=14;  SET @U15:=15;  SET @U16:=16;  SET @U17:=17;  SET @U18:=18;
SET @U19:=19;  SET @U20:=20;  SET @U21:=21;  SET @U22:=22;  SET @U23:=23;  SET @U24:=24;

/* --- Contactos de emergencia (múltiples por usuario, sin duplicados) --- */
INSERT INTO `usuario_contacto` (id_usuario, id_contacto) VALUES
-- Usuario 1 (María): 3 contactos
(@U1,@U2),(@U1,@U3),(@U1,@U4),
-- Usuario 2 (Pedro): 2 contactos
(@U2,@U1),(@U2,@U5),
-- Usuario 3 (Lucía): 2 contactos
(@U3,@U4),(@U3,@U6),
-- Usuario 4 (Sofía): 1 contacto
(@U4,@U3),
-- Usuario 5 (David): 3 contactos
(@U5,@U6),(@U5,@U7),(@U5,@U8),
-- Usuario 6 (Laura): 2 contactos
(@U6,@U5),(@U6,@U1),
-- Usuario 7 (Antonio): 2 contactos
(@U7,@U8),(@U7,@U9),
-- Usuario 8 (Paula): 2 contactos
(@U8,@U7),(@U8,@U10),
-- Usuario 9 (Cristina): 2 contactos
(@U9,@U10),(@U9,@U1),
-- Usuario 10 (José): 2 contactos
(@U10,@U9),(@U10,@U2),
-- Usuario 11 (Elena): 2 contactos
(@U11,@U12),(@U11,@U13),
-- Usuario 12 (Raúl): 1 contacto
(@U12,@U11),
-- Usuario 13 (Clara): 2 contactos
(@U13,@U14),(@U13,@U15),
-- Usuario 14 (Iván): 1 contacto
(@U14,@U13),
-- Usuario 15 (Noa): 2 contactos
(@U15,@U1),(@U15,@U3),
-- Usuario 16 (Héctor): 2 contactos
(@U16,@U2),(@U16,@U4),
-- Usuario 17 (Marta Navas): 2 contactos
(@U17,@U5),(@U17,@U6),
-- Usuario 18 (Julia): 1 contacto
(@U18,@U7),
-- Usuario 19 (Gonzalo): 2 contactos
(@U19,@U8),(@U19,@U9),
-- Usuario 20 (Alicia): 2 contactos
(@U20,@U10),(@U20,@U11),
-- Usuario 21 (Irene): 2 contactos
(@U21,@U12),(@U21,@U13),
-- Usuario 22 (Pablo): 1 contacto
(@U22,@U1),
-- Usuario 23 (Adriana): 2 contactos
(@U23,@U2),(@U23,@U3),
-- Usuario 24 (Samuel): 2 contactos
(@U24,@U4),(@U24,@U5);

/* --- Citas (30) variadas en octubre/noviembre 2025 --- */
INSERT INTO `cita` (fecha, hora_inicio, id_teleoperador) VALUES
('2025-10-03','09:00:00',@TEL_CP), ('2025-10-03','10:30:00',@TEL_CP),
('2025-10-04','11:00:00',@TEL_AT), ('2025-10-04','12:15:00',@TEL_AT),
('2025-10-05','09:45:00',@TEL_MR), ('2025-10-05','16:00:00',@TEL_MR),
('2025-10-06','10:00:00',@TEL_SL), ('2025-10-06','17:30:00',@TEL_SL),
('2025-10-07','08:30:00',@TEL_ER), ('2025-10-07','15:15:00',@TEL_ER),
('2025-10-08','09:10:00',@TEL_DM), ('2025-10-08','13:40:00',@TEL_DM),
('2025-10-09','10:25:00',@TEL_SP), ('2025-10-09','11:55:00',@TEL_SP),
('2025-10-10','09:05:00',@TEL_CP), ('2025-10-10','14:20:00',@TEL_AT),
('2025-10-11','15:00:00',@TEL_MR), ('2025-10-11','16:30:00',@TEL_SL),
('2025-10-12','10:00:00',@TEL_ER), ('2025-10-12','12:30:00',@TEL_DM),
('2025-10-13','09:00:00',@TEL_SP), ('2025-10-13','10:45:00',@TEL_CP),
('2025-10-14','11:15:00',@TEL_AT), ('2025-10-14','12:50:00',@TEL_MR),
('2025-10-15','09:40:00',@TEL_SL), ('2025-10-15','15:10:00',@TEL_ER),
('2025-10-16','10:00:00',@TEL_DM), ('2025-10-16','11:30:00',@TEL_SP),
('2025-11-02','09:00:00',@TEL_CP), ('2025-11-03','09:30:00',@TEL_AT);

/* --- Alertas (sobre ~18 citas) --- */
INSERT INTO `alerta` (id_cita, tipo, descripcion) VALUES
(1,'recordatorio','Recordatorio previo a la cita'),
(2,'incidencia','Cliente no contesta al teléfono'),
(3,'recordatorio','Enviar SMS confirmación'),
(5,'urgente','Reprogramación necesaria'),
(6,'incidencia','Fallo en sistema de llamadas'),
(7,'recordatorio','Confirmar documentación'),
(8,'recordatorio','Verificar disponibilidad'),
(10,'incidencia','Contacto desactualizado'),
(11,'recordatorio','Revisión previa'),
(13,'urgente','Atención prioritaria'),
(14,'recordatorio','Checklist QA'),
(16,'incidencia','Doble reserva detectada'),
(17,'recordatorio','Adjuntar informe'),
(19,'urgente','Caso sensible'),
(21,'recordatorio','Aviso al usuario'),
(24,'incidencia','Corte de línea'),
(25,'recordatorio','Confirmación por email'),
(29,'urgente','Cliente VIP');

/* --- Comunicaciones (20) con supervisión --- */
INSERT INTO `comunicacion` (id_supervisor, fecha, hora_inicio, hora_fin, observaciones) VALUES
(@SUP_LG,'2025-10-03','08:30:00','09:00:00','Revisión de agenda con CP y AT'),
(@SUP_JD,'2025-10-04','10:30:00','11:00:00','Incidencias sobre citas de AT'),
(@SUP_PL,'2025-10-05','09:00:00','09:45:00','Seguimiento productividad MR'),
(@SUP_HR,'2025-10-06','11:15:00','11:45:00','Control de tiempos en SL'),
(@SUP_NV,'2025-10-07','14:00:00','14:30:00','Alertas urgentes en ER'),
(@SUP_LG,'2025-10-08','16:00:00','16:30:00','Revisión semanal DM'),
(@SUP_JD,'2025-10-09','09:00:00','09:30:00','Coaching a SP'),
(@SUP_PL,'2025-10-10','13:00:00','13:45:00','Protocolo de re-confirmación'),
(@SUP_HR,'2025-10-11','10:30:00','11:15:00','Gestión de dobles reservas'),
(@SUP_NV,'2025-10-12','12:00:00','12:45:00','Plan de mejora continua'),
(@SUP_LG,'2025-10-13','09:15:00','09:45:00','Checklist de calidad'),
(@SUP_JD,'2025-10-14','11:00:00','11:20:00','Plantillas de guion'),
(@SUP_PL,'2025-10-15','12:10:00','12:40:00','Auditoría de llamadas'),
(@SUP_HR,'2025-10-16','10:00:00','10:30:00','Feedback individual'),
(@SUP_NV,'2025-10-17','16:10:00','16:40:00','Incidencias técnicas'),
(@SUP_LG,'2025-10-18','09:40:00','10:15:00','Rendimiento por franjas'),
(@SUP_JD,'2025-10-19','11:50:00','12:20:00','Optimización de scripts'),
(@SUP_PL,'2025-10-20','15:05:00','15:35:00','Seguimiento de KPIs'),
(@SUP_HR,'2025-10-21','10:45:00','11:10:00','Cierres del día'),
(@SUP_NV,'2025-10-22','14:25:00','14:55:00','Plan de formación');

/* ===========================================================
    4) Checks rápidos útiles (opcionales)
   =========================================================== */
/* Usuarios con >1 contacto de emergencia */
-- SELECT u.id_persona, u.nombre, u.apellido, COUNT(uc.id_contacto) AS contactos
-- FROM usuario u
-- JOIN usuario_contacto uc ON uc.id_usuario = u.id_persona
-- GROUP BY u.id_persona
-- HAVING COUNT(uc.id_contacto) > 1;

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
