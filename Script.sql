/*Partie 2 : Création des tablespace et utilisateur*/
--Création des tableSpace 
CREATE TABLESPACE SQL3_TBS DATAFILE 'c:\sql3_tbs.dat' SIZE 100M AUTOEXTEND ON ONLINE;
CREATE TEMPORARY TABLESPACE SQL3_TempTBS TEMPFILE 'c:\sql3_temptbs.tmp' SIZE 100M AUTOEXTEND ON;

--Création d'utilisateur 
CREATE USER SQL3 IDENTIFIED BY test
DEFAULT TABLESPACE SQL3_TBS
TEMPORARY TABLESPACE SQL3_TempTBS;

--Donner tous les privilèges à cet utilisateur
GRANT ALL PRIVILEGES TO SQL3;
/*Partie 3 : Langage de définition de données*/
/*
en se basant sur le diagramme de classes fait, définir tous les types nécessaires. Prendre en compte
toutes associations qui existent
*/
--créer les types incomplets
create type tvilles;
/
create type tgymnases;
/
create type tsportifs;
/
create type tsport;
/
create type tseances;
/
create type tjouer;
/
create type tentrainer;
/
create type tarbitrer;
/
-- créer les types pour les tables imbriquées des références
create type tref_instance_gymnases as table of ref tgymnases;
/
create type tref_instance_seances as table of ref tseances;
/
create type tref_instance_sportifs as table of ref tsportifs;
/
create type tref_instance_sport as table of ref tsport;
/
create type tref_instance_jouer as table of ref tjouer;
/
create type tref_instance_arbitrer as table of ref tarbitrer;
/
create type tref_instance_entrainer as table of ref tentrainer;
/
--création des types
create or replace type tvilles as object(villes varchar2(50),villes_gymnases tref_instance_gymnases);
/
create or replace type tsportifs as object(idSportif integer, nom VARCHAR(20), prenom VARCHAR(20), sexe CHAR(1), age integer, idSportifConseiller REF tsportifs, sportifs_sport tref_instance_sport,sportifs_arbitrer tref_instance_arbitrer, sportifs_jouer tref_instance_jouer, sportifs_entrainer tref_instance_entrainer);
/
create or replace type tgymnases as object(idGymnase integer, nomGymnases varchar(100),adresse varchar2(100), gymnases_villes ref tvilles,surface integer, gymnases_seances tref_instance_seances,gymnases_sport tref_instance_sport);
/
create or replace type tsport as object(idSport integer, libelle varchar(20),sport_arbitrer tref_instance_arbitrer, sport_jouer tref_instance_jouer,sport_entrainer tref_instance_entrainer, sport_seance tref_instance_seances, sport_gymnases tref_instance_gymnases);
/
create or replace type tseances as object(seances_gymnases ref tgymnases, seance_sport ref tsport ,seance_entrainer ref tsportifs,jour varchar(25), horaire float, duree integer);
/
create or replace type tarbitrer as object(arbitrer_sportif ref tsportifs, arbitrer_sport ref tsport);
/
create or replace type tjouer as object(jouer_sportif ref tsportifs, jouer_sport ref tsport);
/
create or replace type tentrainer as object(idSportifEntraineur ref tsportifs,entrainer_sport ref tsport);
/
--Définir les tables nécessaires à la base de données:
create table Villes of tvilles(constraint pk_ville primary key(villes))
nested table villes_gymnases store as nt_villes_gymnases;

create table Gymnases of tgymnases(constraint pk_gymnase primary key(idGymnase), constraint fk_ville foreign key(gymnases_villes) references Villes)
nested table gymnases_seances store as nt_gymnases_seances,
nested table gymnases_sport store as nt_gymnases_sport;

create table Sportifs of tsportifs(constraint pk_sportif primary key(idSportif),constraint fk_idSportifConseiller foreign key(idSportifConseiller) references Sportifs, constraint ck_sexe check (sexe IN ('M', 'F')))
nested table sportifs_sport store as nt_sportifs_sport,
nested table sportifs_arbitrer store as nt_sportifs_arbitrer,
nested table sportifs_jouer store as nt_sportifs_jouer,
nested table sportifs_entrainer store as nt_sportifs_entrainer;

create table Sport of tsport(constraint pk_sport primary key(idSport))
nested table sport_arbitrer store as nt_sport_arbitrer,
nested table sport_jouer store as nt_sport_jouer,
nested table sport_entrainer store as nt_sport_entrainer,
nested table sport_seance store as nt_sport_seance,
nested table sport_gymnases store as nt_sport_gymnases;

create table Seances of tseances(constraint ck_jour check (jour IN ('Samedi', 'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi')), constraint fk_Gymnase1 foreign key(seances_gymnases) references Gymnases, constraint fk_Sport1 foreign key(seance_sport) references Sport, constraint fk_idSportifEntraineur foreign key(seance_entrainer) references Sportifs);

create table Arbitrer of tarbitrer( constraint fk_Sportif foreign key(arbitrer_sportif) references Sportifs,constraint fk_Sport foreign key(arbitrer_Sport) references Sport);

create table Entrainer of tentrainer(constraint fk_idSportifEntraineur3 foreign key(idSportifEntraineur) references Sportifs,constraint fk_Sport3 foreign key(entrainer_sport) references Sport);

create table Jouer of tjouer (constraint fk_Sportif2 foreign key(jouer_sportif) references Sportifs ,constraint fk_Sport2 foreign key(jouer_sport) references Sport);

-- Définir les méthodes permettant de 
/*1.Calculer pour chaque sportif, le nombre des sports entrainés: */

ALTER TYPE tsportifs ADD MEMBER FUNCTION nbr_sports_entraines RETURN INTEGER CASCADE;

CREATE OR REPLACE TYPE BODY tsportifs AS 
    MEMBER FUNCTION nbr_sports_entraines RETURN INTEGER IS
    v_nbr_sports INTEGER;
  BEGIN
    SELECT COUNT(*) INTO v_nbr_sports
    FROM TABLE(Sport) WHERE idSportif = self.idSportif;
    RETURN v_nbr_sports;
  END;
END;
/

/*2. Calculer le nombre de gymnases pour chaque sport*/

ALTER TYPE tseances ADD MEMBER FUNCTION nbr_gym_sport RETURN NUMBER CASCADE;
CREATE OR REPLACE TYPE BODY Tseances AS 
  MEMBER FUNCTION nbr_gym_sport RETURN NUMBER 
END;
/


/*3. Calculer la superficie moyenne des gymnases, pour chaque ville.*/
ALTER TYPE tgymnases ADD MEMBER FUNCTION superficie_Moy RETURN NUMBER CASCADE;
CREATE OR REPLACE TYPE BODY TGymnase AS 
  MEMBER FUNCTION superficie_Moy (p_ville IN VARCHAR2) RETURN NUMBER IS 
    v_superficieMoy NUMBER; 
  BEGIN 
    SELECT AVG(surface) INTO v_superficieMoy 
    FROM Villes v, Gymnases g 
    WHERE v.villes = p_ville AND g.gymnases_villes IS NOT NULL AND g.gymnases_villes = REF(v); 
    RETURN v_superficieMoy; 
  END;
END;
/

--Partie VI : Langage de manipulation de données
/*8. Remplir toutes les tables par les instances décrites dans le fichier insert.sql en prenant en considération
les adaptations nécessaires.*/
--table villes
INSERT INTO Villes VALUES(tvilles('Alger centre',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Les sources',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Belouizdad',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Sidi Mhamed',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('El Biar',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('El Mouradia',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Hydra',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Dely Brahim',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Kouba',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Bir Mourad Raïs',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Birkhadem',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('El Achour',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Bordj el kiffan',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Baba hassen',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Chéraga',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Alger',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Hussein Dey',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Béni Messous',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Bordj El Bahri',tref_instance_gymnases()));
INSERT INTO Villes VALUES(tvilles('Mohammadia',tref_instance_gymnases()));
--table gymnases 
INSERT INTO Gymnases VALUES(tgymnases(1,'Five Gym Club','Boulevard Mohamed 5',(select ref (v) from villes v where villes='Alger centre'),200,tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(2,'Mina Sport','28 impasse musette les sources',(select ref (v) from villes v where villes='Les sources'),450, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(3,'Aït Saada','Belouizdad',(select ref (v) from villes v where villes='Belouizdad'),400,tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(4,'Bahri Gym','Rue Mohamed Benzineb',(select ref (v) from villes v where villes='Sidi Mhamed'),500, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(5,'Ladies First','3 Rue Diar Naama N° 03',(select ref (v) from villes v where villes='El Biar'),620, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(6,'C.T.F Club','Rue Sylvain FOURASTIER',(select ref (v) from villes v where villes='El Mouradia'),420, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(7,'Body Fitness Center','Rue Rabah Takdjourt',(select ref (v) from villes v where villes='Alger centre'),360, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(8,'Club Hydra Forme','Rue de l''Oasis',(select ref (v) from villes v where villes='Hydra'),420, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(9,'Profitness Dely Brahim','26 Bois des Cars 3',(select ref (v) from villes v where villes='Dely Brahim'),620, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(10,'CLUB SIFAKS','Rue Ben Omar 31',(select ref (v) from villes v where villes='Kouba'),400, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(11,'Gym ZAAF Club','19 Ave Merabet Athmane',(select ref (v) from villes v where villes='El Mouradia'),300, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(12,'GYM power','villa N°2, Chemin Said Hamdine',(select ref (v) from villes v where villes='Bir Mourad Raïs'),480, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(13,'Icosium sport','Rue ICOSUM',(select ref (v) from villes v where villes='Hydra'),200, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(14,'GIGA Fitness','res, Rue Hamoum Tahar',(select ref (v) from villes v where villes='Birkhadem'),500, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(15,'AC Fitness Et Aqua','Lotissement FAHS lot A n 12 parcelle 26',(select ref (v) from villes v where villes='Birkhadem'),400, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(16,'MELIA GYM','Résidence les deux bassins Sahraoui local N° 03',(select ref (v) from villes v where villes='El Achour'),600, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(17,'Sam Gym Power','Rue Mahdoud BENKHOUDJA',(select ref (v) from villes v where villes='Kouba'),400, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(18,'AQUAFORTLAND SPA','Bordj el kiffan',(select ref (v) from villes v where villes='Bordj el kiffan'),450, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(19,'GoFitness','Lotissement el louz n°264',(select ref (v) from villes v where villes='Baba hassen'),500, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(20,'Best Body Gym','Cité Alioua Fodil',(select ref (v) from villes v where villes='Chéraga'),400, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(21,'Power house gym','Cooperative Amina 02 Lot 15',(select ref (v) from villes v where villes='Alger'),400, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(22,'POWER ZONE GYM','Chemin Fernane Hanafi',(select ref (v) from villes v where villes='Hussein Dey'),500, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(23,'World Gym','14 Boulevard Ibrahim Hadjress',(select ref (v) from villes v where villes='Béni Messous'),520, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(24,'Moving Club','Bordj El Bahri',(select ref (v) from villes v where villes='Bordj El Bahri'),450, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(25,'Tiger gym','Route de Bouchaoui',(select ref (v) from villes v where villes='Chéraga'),620, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(26,'Lion CrossFit','Centre commercial-Mohamadia mall',(select ref (v) from villes v where villes='Mohammadia'),600, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(27,'Étoile sportive','Saoula',(select ref (v) from villes v where villes='Saoula'),350, tref_instance_seances(),tref_instance_sport()));
INSERT INTO Gymnases VALUES(tgymnases(28,'Fitness life gym','El Harrach',(select ref (v) from villes v where villes='El Harrach'),400, tref_instance_seances(),tref_instance_sport()));
--table sportifs
INSERT INTO Sportifs VALUES(tsportifs(1,'BOUTAHAR','Abderahim','M',30,NULL,tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(2,'BOUROUBI','Anis','M',28,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(3,'BOUZIDI','Amel','F',25,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(4,'LACHEMI','Bouzid','M',32,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(5,'AAKOUB','Linda','F',22,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(6,'ABBAS','Sophia','F',30,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(7,'HADJ','Zouhir','M',25,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(8,'HAMADI','Hani','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(9,'ABDELMOUMEN','Nadia','F',23,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(10,'ABAD','Abdelhamid','M',23,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(11,'ABAYAHIA','Amine','M',24,(select ref (s) from sportifs s where idSportif=6),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(12,'ABBACI','Riad','M',24,(select ref (s) from sportifs s where idSportif=8),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(13,'ABBACI','Mohamed','M',22,(select ref (s) from sportifs s where idSportif=13),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(14,'ABDELOUAHAB','Lamia','F',24,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(15,'ABDEMEZIANE','Majid','M',25,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(16,'BENOUADAH','Lamine','M',24,(select ref (s) from sportifs s where idSportif=8),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(17,'ACHAIBOU','Rachid','M',22,(select ref (s) from sportifs s where idSportif=7),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(18,'HOSNI','Leila','F',25,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(19,'ABERKANE','Adel','M',25,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(20,'AZOUG','Racim','M',25,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(21,'BABACI','Mourad','M',22,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(22,'BAKIR','Ayoub','M',25,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(23,'BEHADI','Youcef','M',24,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(24,'AMARA','Nassima','F',23,(select ref (s) from sportifs s where idSportif=7),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(25,'AROUEL','Lyes','M',23,(select ref (s) from sportifs s where idSportif=9),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(26,'BAALI','Leila','F',23,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(27,'BADI','Hatem','M',23,(select ref (s) from sportifs s where idSportif=7),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(28,'RABAHI','Rabah','M',40,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(29,'ROUSSELI','Lamice','F',22,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(30,'CHIKHI','Nidal','M',24,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(31,'SETIHA','Moustapha','M',22,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(32,'COTERI','Daouad','M',23,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(33,'RAMELI','Sami','M',23,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(34,'LEHIRACHE','Oussama','M',24,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(35,'TERIKI','Yacine','M',24,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(36,'DJELOUDANE','Zinedine','M',28,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(37,'LAZARI','Malika','F',25,(select ref (s) from sportifs s where idSportif=44),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(38,'MESSOUNI','Ismail','M',24,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(39,'MORELI','Otheman','M',24,(select ref (s) from sportifs s where idSportif=8),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(40,'FATAHI','Majid','M',23,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(41,'DELHOUME','Elina','F',22,(select ref (s) from sportifs s where idSportif=7),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(42,'BEHADI','Nadir','M',23,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(43,'MATI','Dalia','F',23,(select ref (s) from sportifs s where idSportif=6),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(44,'ADIBOU','Ibrahim','M',28,(select ref (s) from sportifs s where idSportif=21),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(45,'CHALI','Karim','M',25,(select ref (s) from sportifs s where idSportif=NULL),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(46,'DOUDOU','Islam','M',24,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(47,'Grine','Célina','F',25,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(48,'HEDDI','Zohra','F',23,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(49,'JADI','Sandra','F',24,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(50,'KALI','Yasser','M',22,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(51,'LAJEL','Fouad','M',24,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(52,'DANDOUR','Rami','M',22,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(53,'DEMMERA','Houcine','M',22,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(54,'ELKABBADJ','Mohammed','M',23,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(55,'FEROLI','Omer','M',23,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(56,'GUERRAOUI','Zohra','F',25,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(57,'BOUACHA','Aziz','M',25,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(58,'GUITENI','Adam','M',23,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(59,'KACI','Samia','F',23,(select ref (s) from sportifs s where idSportif=NULL),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(60,'TIZEGHAT','Badis','M',32,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(61,'LAZARRI','Jamel','M',27,(select ref (s) from sportifs s where idSportif=7),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(62,'BAZOUDI','Jaouad','M',32,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(63,'AMANI','Fadi','M',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(64,'LANORI','Faiza','F',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(65,'CHAADI','Mourad','M',30,(select ref (s) from sportifs s where idSportif=NULL),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(66,'DANDANE','Mohamed','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(67,'FATTIMI','Dalila','F',26,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(68,'REGHI','Jazia','F',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(69,'MARADI','Hadjer','F',25,(select ref (s) from sportifs s where idSportif=7),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(70,'BELMADI','Nadji','M',30,(select ref (s) from sportifs s where idSportif=9),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(71,'DELAROCHI','Racim','M',30,(select ref (s) from sportifs s where idSportif=8),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(72,'MARTALI','Bouzid','M',22,(select ref (s) from sportifs s where idSportif=8),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(73,'DALLIMI','Douad','M',30,(select ref (s) from sportifs s where idSportif=6),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(74,'OUBACHA','Adel','M',30,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(75,'SAADI','Nihal','F',39,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(76,'HALGATTI','Camelia','F',30,(select ref (s) from sportifs s where idSportif=21),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(77,'HIDDOUCI','Farid','M',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(78,'CHAOUAH','Jamel','M',30,(select ref (s) from sportifs s where idSportif=NULL),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(79,'HANDI','Jaouad','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(80,'HOCHET','Ramezi','M',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(81,'DROULLONI','Jaouida','F',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(82,'HOULEMI','Lyes','M',40,(select ref (s) from sportifs s where idSportif=14),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(83,'LOUATI','Ahmed','M',30,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(84,'SALLADj','Miloud','M',28,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(85,'HAMARI','Anes','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(86,'GALLOTI','Boualem','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(87,'KASBADJI','Fateh','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(88,'JENOURI','Rachid','M',30,(select ref (s) from sportifs s where idSportif=8),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(89,'RIHABI','Jamel','M',30,(select ref (s) from sportifs s where idSportif=NULL),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(90,'DERARNI','Nadir','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(91,'BATERAOUI','Zinedine','M',30,(select ref (s) from sportifs s where idSportif=98),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(92,'HADJI','Jamel','M',22,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(93,'CAUCHARDI','Nabil','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(94,'LEROUDI','Moussa','M',36,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(95,'ESTANBOULI','Mazine','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(96,'JANID','Lamine','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(97,'BONHOMMANE','Bassim','M',30,(select ref (s) from sportifs s where idSportif=NULL),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(98,'RIADI','Walid','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(99,'BONETI','Djalal','M',32,(select ref (s) from sportifs s where idSportif=NULL),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(100,'LESOIFI','Djamil','M',30,(select ref (s) from sportifs s where idSportif=9),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(101,'SWAMI','Esslam','M',30,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(102,'DAOUDI','Adel','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(103,'LAAMOURI','Nasssim','M',30,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(104,'SEHIER','Dihia','F',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(105,'STITOUAH','Fouad','M',30,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(106,'BAADI','Hani','M',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(107,'BOURAS','Nazim','M',30,(select ref (s) from sportifs s where idSportif=9),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(108,'AIT AMARA','Salim','M',30,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(109,'SAGOU','Bassel','M',30,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(110,'ROULLADI','Aissa','M',30,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(111,'BOUTINE','Mohamed','M',30,(select ref (s) from sportifs s where idSportif=8),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(112,'LOUATI','Islam','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(113,'AID','Naim','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(114,'MICHALIKH','Asma','F',22,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(115,'LEMOUSSI','Amine','M',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(116,'BELIFA','Samia','F',30,(select ref (s) from sportifs s where idSportif=8),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(117,'FERRIRA','Manel','F',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(118,'IGHOLI','Lyes','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(119,'GUEMEZ','Jaouad','M',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(120,'LECOM','Aissa','M',30,(select ref (s) from sportifs s where idSportif=6),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(121,'HOUAT','Aziz','M',30,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(122,'BEQUETA','Aicha','F',30,(select ref (s) from sportifs s where idSportif=6),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(123,'RATENI','Walid','M',30,(select ref (s) from sportifs s where idSportif=6),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(124,'TOUAT','Yasmine','F',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(125,'JALONI','Aimad','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(126,'DEBOUBA','yasser','M',30,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(127,'GASTAB','Chouaib','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(128,'GIRONI','Younes','M',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(129,'DABONI','Rachid','M',30,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(130,'LACHOUBI','Kamel','M',30,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(131,'GALLOI','Nadira','F',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(132,'DORONI','Yanis','M',30,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(133,'LENOUCHI','Youcef','M',30,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(134,'LERICHE','Hadi','M',30,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(135,'MANSOUR','Lamine','M',30,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(136,'LABOULAIS','Fadia','F',26,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(137,'DOUDOU','Faiza','F',26,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(138,'MAALEM','Lamia','F',26,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(139,'BESNARD','Salma','F',26,(select ref (s) from sportifs s where idSportif=4),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(140,'BELHAMID','Hadjer','F',26,(select ref (s) from sportifs s where idSportif=7),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(141,'BOUAAZA','Asma','F',26,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(142,'CORCHI','Melissa','F',26,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(143,'BELAID','Jaouida','F',26,(select ref (s) from sportifs s where idSportif=5),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(144,'GASMI','Souad','F',26,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(145,'LAAMARA','Maria','F',25,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(146,'DABOUB','Ramezi','M',25,(select ref (s) from sportifs s where idSportif=3),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(147,'HASSINI','Nadia','F',25,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(148,'KALOUNE','Maria','F',27,(select ref (s) from sportifs s where idSportif=1),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(149,'BELHAOUA','Besma','F',27,(select ref (s) from sportifs s where idSportif=7),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(150,'BELAID','Fouad','M',25,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));
INSERT INTO Sportifs VALUES(tsportifs(151,'HENDI','Mouad','M',25,(select ref (s) from sportifs s where idSportif=2),tref_instance_sport(),tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer()));

--table Sports
INSERT INTO Sport VALUES(tsport(1,'Basket ball',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
INSERT INTO Sport VALUES(tsport(2,'Volley ball',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
INSERT INTO Sport VALUES(tsport(3,'Hand ball',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
INSERT INTO Sport VALUES(tsport(4,'Tennis',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
INSERT INTO Sport VALUES(tsport(5,'Hockey',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
INSERT INTO Sport VALUES(tsport(6,'Badmington',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
INSERT INTO Sport VALUES(tsport(7,'Ping pong',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
INSERT INTO Sport VALUES(tsport(8,'Football',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
INSERT INTO Sport VALUES(tsport(9,'Boxe',tref_instance_arbitrer(),tref_instance_jouer(),tref_instance_entrainer(),tref_instance_seances(),tref_instance_gymnases()));
--table arbitrer
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=1),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=1),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=1),(select ref (x) from Sport x where idSport=5)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=2),(select ref (x) from Sport x where idSport=5)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=2),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=3),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=3),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=3),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=4),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=4),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=4),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=4),(select ref (x) from Sport x where idSport=9)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=5),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=6),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=6),(select ref (x) from Sport x where idSport=5)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=6),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=7),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=7),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=7),(select ref (x) from Sport x where idSport=5)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=19),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=20),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=29),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=32),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=35),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=59),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=60),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=94),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=98),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=105),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=149),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=151),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Arbitrer VALUES(tarbitrer((select ref (s) from Sportifs s where idSportif=151),(select ref (x) from Sport x where idSport=3)));
--table entrainer
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=1),(select ref (v) from Sport v where idSport=1)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=1),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=1),(select ref (v) from Sport v where idSport=3)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=1),(select ref (v) from Sport v where idSport=5)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=1),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=2),(select ref (v) from Sport v where idSport=1)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=2),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=2),(select ref (v) from Sport v where idSport=3)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=2),(select ref (v) from Sport v where idSport=4)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=2),(select ref (v) from Sport v where idSport=5)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=2),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=2),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=2),(select ref (v) from Sport v where idSport=9)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=3),(select ref (v) from Sport v where idSport=1)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=3),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=3),(select ref (v) from Sport v where idSport=3)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=3),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=4),(select ref (v) from Sport v where idSport=1)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=4),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=4),(select ref (v) from Sport v where idSport=9)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=6),(select ref (v) from Sport v where idSport=5)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=6),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=6),(select ref (v) from Sport v where idSport=9)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=7),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=7),(select ref (v) from Sport v where idSport=3)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=7),(select ref (v) from Sport v where idSport=5)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=7),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=29),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=30),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=31),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=32),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=35),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=35),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=36),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=38),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=40),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=40),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=48),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=50),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=56),(select ref (v) from Sport v where idSport=6)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=57),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=57),(select ref (v) from Sport v where idSport=4)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=58),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=58),(select ref (v) from Sport v where idSport=4)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=59),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=59),(select ref (v) from Sport v where idSport=4)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=60),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=60),(select ref (v) from Sport v where idSport=4)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=60),(select ref (v) from Sport v where idSport=7)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=61),(select ref (v) from Sport v where idSport=2)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=61),(select ref (v) from Sport v where idSport=4)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=149),(select ref (v) from Sport v where idSport=1)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=151),(select ref (v) from Sport v where idSport=1)));
INSERT INTO Entrainer VALUES(tentrainer((select ref (s) from Sportifs s where idSportif=151),(select ref (v) from Sport v where idSport=3)));

--table Jouer
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=1),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=1),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=1),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=2),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=2),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=2),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=2),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=3),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=3),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=4),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=4),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=5),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=5),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=5),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=5),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=6),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=6),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=6),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=6),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=7),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=7),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=7),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=9),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=9),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=9),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=10),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=10),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=10),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=10),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=11),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=11),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=11),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=12),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=12),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=12),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=13),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=13),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=13),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=14),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=14),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=14),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=15),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=15),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=15),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=16),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=16),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=17),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=17),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=17),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=18),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=19),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=19),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=19),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=20),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=20),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=20),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=20),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=20),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=21),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=21),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=21),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=21),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=22),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=22),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=22),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=22),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=23),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=23),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=23),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=24),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=24),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=24),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=24),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=25),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=25),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=25),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=25),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=25),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=26),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=26),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=26),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=26),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=27),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=27),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=27),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=27),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=27),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=28),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=28),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=28),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=28),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=28),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=29),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=29),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=29),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=29),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=30),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=30),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=30),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=30),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=31),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=31),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=31),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=31),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=32),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=32),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=32),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=32),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=32),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=32),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=33),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=33),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=33),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=33),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=34),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=34),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=34),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=34),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=35),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=35),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=35),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=35),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=35),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=36),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=36),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=36),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=36),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=37),(select ref (x) from Sport x where idSport=2)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=38),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=38),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=38),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=39),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=39),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=40),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=40),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=40),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=40),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=40),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=41),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=41),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=42),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=42),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=42),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=43),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=43),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=43),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=44),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=44),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=44),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=45),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=45),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=46),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=46),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=47),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=48),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=48),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=48),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=49),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=49),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=50),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=50),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=50),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=50),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=51),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=51),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=51),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=51),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=52),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=52),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=52),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=52),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=53),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=53),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=53),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=53),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=54),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=54),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=54),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=55),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=55),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=55),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=56),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=56),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=57),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=57),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=58),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=58),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=58),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=58),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=59),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=59),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=59),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=60),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=60),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=60),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=61),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=62),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=63),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=63),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=63),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=64),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=65),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=66),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=67),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=67),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=68),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=69),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=69),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=69),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=70),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=70),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=71),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=71),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=72),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=72),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=72),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=72),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=73),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=73),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=74),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=74),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=75),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=75),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=76),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=77),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=77),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=77),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=78),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=79),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=80),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=80),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=80),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=82),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=83),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=83),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=83),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=84),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=84),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=85),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=85),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=85),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=86),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=86),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=87),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=87),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=88),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=88),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=88),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=89),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=89),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=90),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=90),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=91),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=91),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=91),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=92),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=92),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=93),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=94),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=94),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=94),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=94),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=95),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=96),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=96),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=97),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=97),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=98),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=98),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=98),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=98),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=99),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=100),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=100),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=101),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=101),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=101),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=102),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=102),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=103),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=103),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=104),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=104),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=105),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=105),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=105),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=105),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=106),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=107),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=108),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=108),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=108),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=109),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=109),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=109),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=109),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=110),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=110),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=110),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=111),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=111),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=112),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=112),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=113),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=113),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=114),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=114),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=114),(select ref (x) from Sport x where idSport=6)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=115),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=118),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=118),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=118),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=119),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=120),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=120),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=121),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=122),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=123),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=123),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=123),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=123),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=124),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=125),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=125),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=125),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=126),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=126),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=127),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=127),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=128),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=128),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=129),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=129),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=129),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=130),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=132),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=132),(select ref (x) from Sport x where idSport=7)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=132),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=133),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=134),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=135),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=135),(select ref (x) from Sport x where idSport=8)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=136),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=137),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=138),(select ref (x) from Sport x where idSport=3)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=138),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=139),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=140),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=141),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=142),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=143),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=144),(select ref (x) from Sport x where idSport=4)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=149),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=151),(select ref (x) from Sport x where idSport=1)));
INSERT INTO Jouer VALUES(tjouer((select ref (s) from Sportifs s where idSportif=151),(select ref (x) from Sport x where idSport=3)));

--table Seances 
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=1),(select ref (d) from Sportifs d where idSportif=149),'Samedi',9.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=1),'Lundi',9.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=1),'Lundi',10.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=1),'Lundi',11.3,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=1),'Lundi',14.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=1),'Lundi',17.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=1),'Lundi',19.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=2),'Dimanche',17.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=2),'Dimanche',19.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=2),'Mardi',17.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=2),'Mercredi',17.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=2),'Samedi',15.3,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=2),'Samedi',16.3,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=2),'Samedi',17.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=3),'Jeudi',20.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=3),'Lundi',14.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=3),'Lundi',18.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=3),'Lundi',19.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=3),'Lundi',20.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=1),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Mercredi',17.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=2),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Dimanche',17.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=3),(select ref (s) from Sport s where idSport=1),(select ref (d) from Sportifs d where idSportif=149),'Mercredi',11.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=3),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Lundi',16.3,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=3),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Jeudi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=4),(select ref (s) from Sport s where idSport=1),(select ref (d) from Sportifs d where idSportif=149),'Vendredi',10.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=4),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Mercredi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=5),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Lundi',16.3,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=5),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Jeudi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=6),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Vendredi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=6),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'jeudi',17.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=8),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Dimanche',17.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=8),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Lundi',16.3,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=8),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Vendredi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=8),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Samedi',17.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=8),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Vendredi',14.0,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=9),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Samedi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=10),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Samedi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=10),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Dimanche',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=10),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Dimanche',17.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=12),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Dimanche',17.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=13),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Dimanche',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=13),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Mercredi',20.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=13),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Lundi',17.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=14),(select ref (s) from Sport s where idSport=1),(select ref (d) from Sportifs d where idSportif=149),'Mardi',10.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=14),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Dimanche',17.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=15),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Lundi',16.3,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=16),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Lundi',16.3,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=16),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Lundi',17.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=16),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Lundi',18.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=16),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'lundi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=16),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Lundi',20.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=16),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Mercredi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=17),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=3),'Samedi',17.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=17),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=3),'Vendredi',17.3,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=17),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Dimanche',17.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=17),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=3),'Dimanche',18.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=17),(select ref (s) from Sport s where idSport=3),(select ref (d) from Sportifs d where idSportif=3),'Mardi',20.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=17),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Mardi',17.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=18),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Lundi',16.3,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=18),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Mardi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=18),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Mercredi',14.0,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=18),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Mercredi',16.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=19),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Dimanche',17.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=20),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Mercredi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=21),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Lundi',16.3,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=21),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=60),'Mardi',19.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=21),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Mercredi',17.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=22),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Mardi',10.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=24),(select ref (s) from Sport s where idSport=1),(select ref (d) from Sportifs d where idSportif=149),'Jeudi',9.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=24),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Mercredi',10.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=25),(select ref (s) from Sport s where idSport=1),(select ref (d) from Sportifs d where idSportif=149),'Dimanche',18.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=27),(select ref (s) from Sport s where idSport=2),(select ref (d) from Sportifs d where idSportif=57),'Jeudi',10.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=27),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Mercredi',14.0,120));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=27),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Mercredi',17.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=28),(select ref (s) from Sport s where idSport=1),(select ref (d) from Sportifs d where idSportif=149),'Lundi',9.0,30));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=28),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Dimanche',14.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=28),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Dimanche',15.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=28),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Dimanche',16.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=28),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=6),'Dimanche',17.0,60));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=28),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Mardi',18.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=28),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Samedi',18.0,90));
INSERT INTO Seances VALUES(tseances((select ref (g) from Gymnases g where idGymnase=28),(select ref (s) from Sport s where idSport=5),(select ref (d) from Sportifs d where idSportif=7),'Vendredi',18.0,90));



--Partie V :  Langage d’interrogation de données
--9/Quels sont les sportifs (identifiant, nom et prénom) qui ont un âge  entre 20 et 30 ans ?

SELECT idSportif, nom, prenom
FROM sportifs
WHERE age BETWEEN 20 AND 30;


--10/Afficher la superficie moyenne des gymnases, pour chaque ville.

SELECT (g.gymnases_villes).villes, AVG(g.SURFACE) AS SUPERFICIE_MOYENNE
FROM GYMNASES g
WHERE (g.gymnases_villes).villes IS NOT NULL 
GROUP BY (g.gymnases_villes).villes
ORDER BY (g.gymnases_villes).villes ASC;

--11/Quels sont les sportifs qui sont des conseillers ?

SELECT DISTINCT DEREF(s1.idSportifConseiller).NOM,DEREF(s1.idSportifConseiller).prenom
FROM Sportifs s1
WHERE s1.idSportifConseiller IS NOT NULL;

--12/Quels entraîneurs n’entraînent que du hand ball ou du basket ball ?

SELECT DISTINCT DEREF(t.idSportifEntraineur).nom, DEREF(t.entrainer_sport).libelle
FROM (
  SELECT e.idSportifEntraineur, e.entrainer_sport
  FROM entrainer e
) t
WHERE DEREF(t.entrainer_sport).idSport IN (1, 3);


--13/ Quels sont les sportifs les plus jeunes?

SELECT NOM, PRENOM,AGE FROM SPORTIFS WHERE AGE = (SELECT MIN(AGE) FROM SPORTIFS);

