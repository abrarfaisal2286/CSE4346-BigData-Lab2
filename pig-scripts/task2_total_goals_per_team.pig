-- Task 2: GROUP + aggregate
-- Computes total goals scored by each team, combining their home and away
-- appearances across both leagues.

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

epl_clean = FILTER epl_raw BY Date != 'Date';
laliga_clean = FILTER laliga_raw BY Date != 'Date';

all_matches = UNION epl_clean, laliga_clean;

-- Split into a home-goals view and an away-goals view, then combine them
home_goals = FOREACH all_matches GENERATE HomeTeam AS Team, FTHG AS Goals;
away_goals = FOREACH all_matches GENERATE AwayTeam AS Team, FTAG AS Goals;
all_goals = UNION home_goals, away_goals;

grouped = GROUP all_goals BY Team;
team_totals = FOREACH grouped GENERATE group AS Team, SUM(all_goals.Goals) AS TotalGoals;

STORE team_totals INTO 'output/pig_task2_total_goals' USING PigStorage(',');
