-- Task 4: JOIN
-- Builds a small Team -> League/Country lookup table (derived from the same
-- data, so team-name spelling always matches exactly), then JOINs the match
-- data against it to attach each match's country.

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

epl_tagged = FOREACH epl_clean GENERATE Date, HomeTeam, AwayTeam, FTHG, FTAG, 'EPL' AS League;
laliga_tagged = FOREACH laliga_clean GENERATE Date, HomeTeam, AwayTeam, FTHG, FTAG, 'LaLiga' AS League;

all_matches = UNION epl_tagged, laliga_tagged;

-- Build the Team -> League/Country lookup table from the same tagged data
epl_teams = FOREACH epl_tagged GENERATE HomeTeam AS TeamName, League;
laliga_teams = FOREACH laliga_tagged GENERATE HomeTeam AS TeamName, League;
all_teams = UNION epl_teams, laliga_teams;
team_league = DISTINCT all_teams;

team_lookup = FOREACH team_league GENERATE TeamName, League,
    (League == 'EPL' ? 'England' : 'Spain') AS Country;

-- JOIN each match's home team against the lookup table to attach its country
matches_with_country = JOIN all_matches BY HomeTeam, team_lookup BY TeamName;

result = FOREACH matches_with_country GENERATE
    all_matches::Date AS Date,
    all_matches::HomeTeam AS HomeTeam,
    all_matches::AwayTeam AS AwayTeam,
    all_matches::FTHG AS FTHG,
    all_matches::FTAG AS FTAG,
    team_lookup::Country AS Country;

-- JOIN doesn't guarantee any particular row order, so sort explicitly for a
-- readable, presentable result
sorted_result = ORDER result BY Date;

STORE sorted_result INTO 'output/pig_task4_matches_with_country' USING PigStorage(',');
