-- Task 1: FILTER
-- Loads both leagues, tags each with its League, combines them, and filters
-- down to high-scoring matches (more than 4 total goals).

epl_raw = LOAD 'dataset/epl_2425.csv' USING PigStorage(',') AS
    (Date:chararray, HomeTeam:chararray, AwayTeam:chararray, FTHG:int, FTAG:int, FTR:chararray,
     HTHG:int, HTAG:int, HTR:chararray, Referee:chararray, HomeShots:int, AwayShots:int,
     HomeShotsTarget:int, AwayShotsTarget:int, HomeFouls:int, AwayFouls:int, HomeCorners:int,
     AwayCorners:int, HomeYellow:int, AwayYellow:int, HomeRed:int, AwayRed:int);

laliga_raw = LOAD 'dataset/laliga_2425.csv' USING PigStorage(',') AS
    (Date:chararray, HomeTeam:chararray, AwayTeam:chararray, FTHG:int, FTAG:int, FTR:chararray,
     HTHG:int, HTAG:int, HTR:chararray, Referee:chararray, HomeShots:int, AwayShots:int,
     HomeShotsTarget:int, AwayShotsTarget:int, HomeFouls:int, AwayFouls:int, HomeCorners:int,
     AwayCorners:int, HomeYellow:int, AwayYellow:int, HomeRed:int, AwayRed:int);

-- Drop the header row from each file (its Date field is the literal string 'Date')
epl_clean = FILTER epl_raw BY Date != 'Date';
laliga_clean = FILTER laliga_raw BY Date != 'Date';

-- Tag each match with which league it came from
epl_tagged = FOREACH epl_clean GENERATE Date, HomeTeam, AwayTeam, FTHG, FTAG, 'EPL' AS League;
laliga_tagged = FOREACH laliga_clean GENERATE Date, HomeTeam, AwayTeam, FTHG, FTAG, 'LaLiga' AS League;

all_matches = UNION epl_tagged, laliga_tagged;

-- Compute total goals per match, then filter for high-scoring games
with_total = FOREACH all_matches GENERATE Date, HomeTeam, AwayTeam, League, (FTHG + FTAG) AS TotalGoals;

high_scoring = FILTER with_total BY TotalGoals > 4;

STORE high_scoring INTO 'output/pig_task1_high_scoring' USING PigStorage(',');
