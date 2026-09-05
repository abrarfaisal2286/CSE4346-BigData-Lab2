import java.io.IOException;
import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;

/**
 * Task 1: Total goals scored per team, combining home and away appearances,
 * across both the EPL and La Liga input files.
 *
 * Input columns (0-indexed): Date(0), HomeTeam(1), AwayTeam(2), FTHG(3),
 * FTAG(4), FTR(5), ...
 *
 * Output: <TeamName>  <TotalGoalsScored>
 */
public class TotalGoalsPerTeam {

    public static class GoalsMapper extends Mapper<Object, Text, Text, IntWritable> {

        private final Text teamKey = new Text();
        private final IntWritable goals = new IntWritable();

        @Override
        public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
            String line = value.toString().trim();
            if (line.isEmpty() || line.startsWith("Date,")) {
                return; // skip blank lines and the header row
            }

            String[] fields = line.split(",", -1);
            if (fields.length < 5) {
                return; // malformed row, skip
            }

            String homeTeam = fields[1].trim();
            String awayTeam = fields[2].trim();

            try {
                int homeGoals = Integer.parseInt(fields[3].trim());
                int awayGoals = Integer.parseInt(fields[4].trim());

                teamKey.set(homeTeam);
                goals.set(homeGoals);
                context.write(teamKey, goals);

                teamKey.set(awayTeam);
                goals.set(awayGoals);
                context.write(teamKey, goals);
            } catch (NumberFormatException e) {
                // skip rows with missing/invalid goal counts
            }
        }
    }

    public static class GoalsReducer extends Reducer<Text, IntWritable, Text, IntWritable> {

        private final IntWritable result = new IntWritable();

        @Override
        public void reduce(Text key, Iterable<IntWritable> values, Context context)
                throws IOException, InterruptedException {
            int sum = 0;
            for (IntWritable val : values) {
                sum += val.get();
            }
            result.set(sum);
            context.write(key, result);
        }
    }

    public static void main(String[] args) throws Exception {
        if (args.length < 2) {
            System.err.println("Usage: TotalGoalsPerTeam <input path> <output path>");
            System.exit(1);
        }

        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "Total Goals Per Team");
        job.setJarByClass(TotalGoalsPerTeam.class);
        job.setMapperClass(GoalsMapper.class);
        job.setCombinerClass(GoalsReducer.class);
        job.setReducerClass(GoalsReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);

        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
