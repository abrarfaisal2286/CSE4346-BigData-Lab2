-- Task 5: GROUP + nested FOREACH
-- Builds a full per-team summary: matches played, wins/draws/losses, goals
-- for/against, and goal difference, then ranks teams by goal difference.

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

-- Home-team perspective: goals for/against and the result from that team's view
home_perspective = FOREACH all_matches GENERATE
    HomeTeam AS Team, FTHG AS GoalsFor, FTAG AS GoalsAgainst,
    (FTR == 'H' ? 'WIN' : (FTR == 'D' ? 'DRAW' : 'LOSS')) AS Result;

-- Away-team perspective: same idea, mirrored
away_perspective = FOREACH all_matches GENERATE
    AwayTeam AS Team, FTAG AS GoalsFor, FTHG AS GoalsAgainst,
    (FTR == 'A' ? 'WIN' : (FTR == 'D' ? 'DRAW' : 'LOSS')) AS Result;

team_matches = UNION home_perspective, away_perspective;

grouped_teams = GROUP team_matches BY Team;

-- Nested FOREACH: for each team, filter its own matches into win/draw/loss
-- sub-relations and count/sum across all of them in one pass
team_summary = FOREACH grouped_teams {
    wins   = FILTER team_matches BY Result == 'WIN';
    draws  = FILTER team_matches BY Result == 'DRAW';
    losses = FILTER team_matches BY Result == 'LOSS';
    GENERATE
        group AS Team,
        COUNT(team_matches) AS MatchesPlayed,
        COUNT(wins) AS Wins,
        COUNT(draws) AS Draws,
        COUNT(losses) AS Losses,
        SUM(team_matches.GoalsFor) AS GoalsFor,
        SUM(team_matches.GoalsAgainst) AS GoalsAgainst,
        (SUM(team_matches.GoalsFor) - SUM(team_matches.GoalsAgainst)) AS GoalDifference;
};

final_summary = ORDER team_summary BY GoalDifference DESC;

STORE final_summary INTO 'output/pig_task5_team_summary' USING PigStorage(',');
