import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.input.FileSplit;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/**
 * Task 3: Compare EPL vs La Liga on goals per match. The league is detected
 * from the input file's name, so the input directory must contain a file
 * with "laliga" in its name (e.g. laliga_2425.csv) and the EPL file named
 * anything else (e.g. epl_2425.csv).
 *
 * Input columns (0-indexed): Date(0), HomeTeam(1), AwayTeam(2), FTHG(3),
 * FTAG(4), ...
 *
 * Output: <League>   Matches=<n>, TotalGoals=<n>, AvgGoalsPerMatch=<x.xx>
 */
public class LeagueGoalsComparison {

    public static class LeagueMapper extends Mapper<Object, Text, Text, IntWritable> {

        private final Text leagueKey = new Text();
        private final IntWritable totalGoals = new IntWritable();

        @Override
        public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
            String line = value.toString().trim();
            if (line.isEmpty() || line.startsWith("Date,")) {
                return;
            }

            String[] fields = line.split(",", -1);
            if (fields.length < 5) {
                return;
            }

            try {
                int homeGoals = Integer.parseInt(fields[3].trim());
                int awayGoals = Integer.parseInt(fields[4].trim());

                FileSplit fileSplit = (FileSplit) context.getInputSplit();
                String fileName = fileSplit.getPath().getName().toLowerCase();
                String league = fileName.contains("laliga") ? "LaLiga" : "EPL";

                leagueKey.set(league);
                totalGoals.set(homeGoals + awayGoals);
                context.write(leagueKey, totalGoals);
            } catch (NumberFormatException e) {
                // skip rows with missing/invalid goal counts
            }
        }
    }

    public static class LeagueReducer extends Reducer<Text, IntWritable, Text, Text> {

        @Override
        public void reduce(Text key, Iterable<IntWritable> values, Context context)
                throws IOException, InterruptedException {
            int totalGoals = 0;
            int matchCount = 0;

            for (IntWritable val : values) {
                totalGoals += val.get();
                matchCount++;
            }

            double average = matchCount == 0 ? 0.0 : (double) totalGoals / matchCount;
            String summary = String.format("Matches=%d, TotalGoals=%d, AvgGoalsPerMatch=%.2f",
                    matchCount, totalGoals, average);

            context.write(key, new Text(summary));
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("Usage: LeagueGoalsComparison <input path> <output path>");
            System.exit(1);
        }

        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "League Goals Comparison");
        job.setJarByClass(LeagueGoalsComparison.class);
        job.setMapperClass(LeagueMapper.class);
        job.setReducerClass(LeagueReducer.class);

        job.setMapOutputKeyClass(Text.class);
        job.setMapOutputValueClass(IntWritable.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(Text.class);

        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
