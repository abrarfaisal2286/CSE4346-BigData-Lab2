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
 * Task 2: Count Win/Draw/Loss outcomes per team, from both the home and away
 * perspective, across both input files.
 *
 * Input columns (0-indexed): Date(0), HomeTeam(1), AwayTeam(2), FTHG(3),
 * FTAG(4), FTR(5) -> H=Home win, D=Draw, A=Away win.
 *
 * Output: <TeamName>,<WIN|DRAW|LOSS>   <Count>
 */
public class MatchOutcomesPerTeam {

    public static class OutcomeMapper extends Mapper<Object, Text, Text, IntWritable> {

        private static final IntWritable ONE = new IntWritable(1);
        private final Text outKey = new Text();

        @Override
        public void map(Object key, Text value, Context context) throws IOException, InterruptedException {
            String line = value.toString().trim();
            if (line.isEmpty() || line.startsWith("Date,")) {
                return;
            }

            String[] fields = line.split(",", -1);
            if (fields.length < 6) {
                return;
            }

            String homeTeam = fields[1].trim();
            String awayTeam = fields[2].trim();
            String result = fields[5].trim(); // FTR: H, D, or A

            String homeOutcome;
            String awayOutcome;

            switch (result) {
                case "H":
                    homeOutcome = "WIN";
                    awayOutcome = "LOSS";
                    break;
                case "A":
                    homeOutcome = "LOSS";
                    awayOutcome = "WIN";
                    break;
                case "D":
                    homeOutcome = "DRAW";
                    awayOutcome = "DRAW";
                    break;
                default:
                    return; // skip rows with an unexpected/missing result code
            }

            outKey.set(homeTeam + "," + homeOutcome);
            context.write(outKey, ONE);

            outKey.set(awayTeam + "," + awayOutcome);
            context.write(outKey, ONE);
        }
    }

    public static class OutcomeReducer extends Reducer<Text, IntWritable, Text, IntWritable> {

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
            System.err.println("Usage: MatchOutcomesPerTeam <input path> <output path>");
            System.exit(1);
        }

        Configuration conf = new Configuration();
        Job job = Job.getInstance(conf, "Match Outcomes Per Team");
        job.setJarByClass(MatchOutcomesPerTeam.class);
        job.setMapperClass(OutcomeMapper.class);
        job.setCombinerClass(OutcomeReducer.class);
        job.setReducerClass(OutcomeReducer.class);
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);

        FileInputFormat.addInputPath(job, new Path(args[0]));
        FileOutputFormat.setOutputPath(job, new Path(args[1]));

        System.exit(job.waitForCompletion(true) ? 0 : 1);
    }
}
