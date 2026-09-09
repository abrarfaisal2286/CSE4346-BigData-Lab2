-- Task 3: ORDER
-- Same per-team goal totals as Task 2, but ranked descending to surface the
-- top 10 highest-scoring teams across both leagues.

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

home_goals = FOREACH all_matches GENERATE HomeTeam AS Team, FTHG AS Goals;
away_goals = FOREACH all_matches GENERATE AwayTeam AS Team, FTAG AS Goals;
all_goals = UNION home_goals, away_goals;

grouped = GROUP all_goals BY Team;
team_totals = FOREACH grouped GENERATE group AS Team, SUM(all_goals.Goals) AS TotalGoals;

ranked_teams = ORDER team_totals BY TotalGoals DESC;
top10 = LIMIT ranked_teams 10;

STORE top10 INTO 'output/pig_task3_top_scoring_teams' USING PigStorage(',');
