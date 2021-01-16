package com.superpowered.VADNCAndroid;

import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.media.AudioManager;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.preference.PreferenceManager;
import android.support.v7.app.AlertDialog;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.text.Html;
import android.text.method.ScrollingMovementMethod;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.widget.EditText;
import android.widget.SeekBar;
import android.widget.SeekBar.OnSeekBarChangeListener;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Button;
import java.io.File;
import java.util.ArrayList;
import java.util.Date;

import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.List;

import static android.graphics.Color.argb;

public class MainActivity extends AppCompatActivity {

    SeekBar samplingRate, quietAdjustment;
    Switch playAudioSwitch,storeFeaturesSwitch;
    EditText frameSize, decisionRate;
    Button startButton, stopButton, readFileButton;
    String fileName,
            folderName = Environment.getExternalStorageDirectory().toString() + "/VAD_NCAndroid/",
            audioFileName;
    String samplerateString = null, buffersizeString = null;
    TextView noiseLabel, speechLabel, quietLabel, noiseStatusView;
    int quiet = argb(64,0,26,153),
            noise = argb(64,153,0,77),
            speech = argb(64,0,153,77),
            white = argb(0,0,0,0);
    SharedPreferences prefs;
    SharedPreferences.Editor prefEdit;
    public static final String appPreferences = "appPrefs";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        getSupportActionBar().setTitle(Html.fromHtml("<small>Integrated App: VAD and Noise Classifier</small>"));
        initializeIds();
        prefs = PreferenceManager.getDefaultSharedPreferences(this);
        prefEdit = prefs.edit();
        loadUserDefaults();
        enableButtons();
        setLabelColor(-1);
        TextView samplingRateText = (TextView) findViewById(R.id.samplingRateText);
        TextView quietAdjustmentText = (TextView) findViewById(R.id.quietAdjustmentText);
        samplingRateText.setText("Sampling Frequency: " + getSamplingRate() + "Hz");
        quietAdjustmentText.setText("Quiet Adjustment: " + (quietAdjustment.getProgress()));

        samplingRate.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {

            int progress = 3;
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {
                // TODO Auto-generated method stub
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {
                // TODO Auto-generated method stub
            }
            @Override
            public void onProgressChanged(SeekBar seekBar, int progressValue, boolean fromUser) {
                TextView samplingRateText = (TextView) findViewById(R.id.samplingRateText);
                samplingRateText.setText("Sampling Frequency: " + getSamplingRate() + "Hz");
            }
        });
        quietAdjustment.setOnSeekBarChangeListener(new OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                TextView quietAdjustmentText = (TextView) findViewById(R.id.quietAdjustmentText);
                quietAdjustmentText.setText("Quiet Adjustment: " + (quietAdjustment.getProgress()));
            }

            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {

            }
        });
        if (Build.VERSION.SDK_INT >= 17) {
            AudioManager audioManager = (AudioManager) this.getSystemService(Context.AUDIO_SERVICE);
            Log.d("Sampling Rate",audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE));
            Log.d("Frame Size",audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER));
        }

        File folder = new File(folderName);
        if(!folder.exists()){
            folder.mkdirs();
        }



    }

    public void setUserDefaults(){

        if(prefs.getBoolean("Initialized", false)) {
            prefEdit.putInt("Sampling Frequency", samplingRate.getProgress());
            prefEdit.putString("Frame Size", frameSize.getText().toString());
            prefEdit.putString("Decision Rate", decisionRate.getText().toString());
            prefEdit.putInt("Quiet Adjustment", quietAdjustment.getProgress());
            prefEdit.putBoolean("Play Audio", playAudioSwitch.isChecked());
            prefEdit.apply();
        }
        else {
            prefEdit.putBoolean("Initialized", true);
            prefEdit.putInt("Sampling Frequency", 8);
            prefEdit.putString("Frame Size", "10.00");
            prefEdit.putString("Decision Rate", "1.0");
            prefEdit.putInt("Quiet Adjustment", 60);
            prefEdit.putBoolean("Play Audio", false);
            prefEdit.apply();
        }

    }
    public void loadUserDefaults(){
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
        if(prefs.getBoolean("Initialized", false)) {
            samplingRate.setProgress(prefs.getInt("Sampling Frequency",8));
            frameSize.setText(prefs.getString("Frame Size", "10.00"));
            decisionRate.setText(prefs.getString("Decision Rate", "1.0"));
            quietAdjustment.setProgress(prefs.getInt("Quiet Adjustment", 60));
            playAudioSwitch.setChecked(prefs.getBoolean("Play Audio", false));
        }
    }

    public void enableButtons(){
        samplingRate.setEnabled(true);
        quietAdjustment.setEnabled(true);
        playAudioSwitch.setEnabled(true);
        storeFeaturesSwitch.setEnabled(true);
        frameSize.setEnabled(true);
        decisionRate.setEnabled(true);
        startButton.setEnabled(true);
        readFileButton.setEnabled(true);
        stopButton.setEnabled(false);
    }

    public void disableButtons(){
        samplingRate.setEnabled(false);
        quietAdjustment.setEnabled(false);
        playAudioSwitch.setEnabled(false);
        storeFeaturesSwitch.setEnabled(false);
        frameSize.setEnabled(false);
        decisionRate.setEnabled(false);
        startButton.setEnabled(false);
        readFileButton.setEnabled(false);
        stopButton.setEnabled(true);
    }

    public void initializeIds(){
        samplingRate = (SeekBar) findViewById(R.id.samplingRateSeekbar);
        quietAdjustment = (SeekBar) findViewById(R.id.quietAdjustmentSeekbar);
        playAudioSwitch = (Switch) findViewById(R.id.switchPlayAudio);
        storeFeaturesSwitch = (Switch) findViewById(R.id.switchStoreFeatures);
        frameSize = (EditText) findViewById(R.id.frameSize);
        decisionRate = (EditText) findViewById(R.id.decisionRate);
        startButton = (Button) findViewById(R.id.buttonStart);
        stopButton = (Button) findViewById(R.id.buttonStop);
        readFileButton = (Button) findViewById(R.id.buttonRead);
        noiseLabel = (TextView) findViewById(R.id.noiseLabel);
        speechLabel = (TextView) findViewById(R.id.speechLabel);
        quietLabel = (TextView) findViewById(R.id.quietLabel);
        noiseStatusView = (TextView) findViewById(R.id.noiseClassifierStatus);
    }

    public void onStartClick(View view) {

        setUserDefaults();
        disableButtons();
        int bufferSize;
        bufferSize = (int) ((getSamplingRate() * Float.parseFloat(frameSize.getText().toString()))/(2*1000));
        noiseStatusView.append("\nRecording Started\n");
        if(storeFeaturesSwitch.isChecked()){
            fileName = folderName + new SimpleDateFormat("yyyy_MM_dd_HH_mm_ss").format(new Date()) + ".txt";
            Log.d("Filename",fileName);
        }
        // Get the device's sample rate and buffer size to enable low-latency Android audio output, if available.

        if (Build.VERSION.SDK_INT >= 17) {
            //AudioManager audioManager = (AudioManager) this.getSystemService(Context.AUDIO_SERVICE);
            samplerateString = Integer.toString(getSamplingRate());//audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE);
            buffersizeString = Integer.toString(bufferSize); //audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER);
        }

        if (samplerateString == null) samplerateString = "44100";
        if (buffersizeString == null) buffersizeString = "512";

        System.loadLibrary("FrequencyDomain");
        FrequencyDomain(Integer.parseInt(samplerateString),
                Integer.parseInt(buffersizeString),
                Float.parseFloat(decisionRate.getText().toString()),
                (float) (quietAdjustment.getProgress()),
                playAudioSwitch.isChecked(),
                storeFeaturesSwitch.isChecked(),
                fileName);

        handler.postDelayed(r,1000);

    }

    public void onStopClick(View view) {
        enableButtons();
        setLabelColor(-1);
        System.loadLibrary("FrequencyDomain");
        StopAudio(fileName, audioFileName);
        handler.removeCallbacks(r);
    }
    public void getTime(){
        TextView processingTime = (TextView) findViewById(R.id.frameProcessingTime);
        TextView dbpower = (TextView) findViewById(R.id.dBPower);
        processingTime.setText("Frame Processing Time: " + new DecimalFormat("##.##").format(getExecutionTime()) + " ms");
        dbpower.setText("SPL: " + new DecimalFormat("##").format(getdbPower()) + " dB");
        setLabelColor(getDetectedClass());

        noiseStatusView.setMovementMethod(new ScrollingMovementMethod());
        if(getDetectedClass()==1) {//Noise classifier shows result if vad detects noise
            String noiseLabel = null;
            if (getDetectedNoiseClass()==1){
                noiseLabel = "Babble";
            } else if (getDetectedNoiseClass()==2){
                noiseLabel = "Machinery";
            } else if (getDetectedNoiseClass()==3) {
                noiseLabel = "Traffic";
            } else {
                noiseLabel = "Quiet";
            }
            noiseStatusView.append("\nDetected Class:" + noiseLabel);
            final int scrollAmount = noiseStatusView.getLayout().getLineTop(noiseStatusView.getLineCount()) - noiseStatusView.getHeight();
            if (scrollAmount > 0)
                noiseStatusView.scrollTo(0, scrollAmount);
            else
                noiseStatusView.scrollTo(0, 0);
        }

    }
    public void setLabelColor(int detectedClass){
        switch (detectedClass) {
            case 0:
                quietLabel.setBackgroundColor(quiet);
                noiseLabel.setBackgroundColor(white);
                speechLabel.setBackgroundColor(white);
                break;
            case 1:
                quietLabel.setBackgroundColor(white);
                noiseLabel.setBackgroundColor(noise);
                speechLabel.setBackgroundColor(white);
                break;
            case 2:
                quietLabel.setBackgroundColor(white);
                noiseLabel.setBackgroundColor(white);
                speechLabel.setBackgroundColor(speech);
                break;
            default:
                quietLabel.setBackgroundColor(white);
                noiseLabel.setBackgroundColor(white);
                speechLabel.setBackgroundColor(white);
                break;
        }
    }



    public void onReadClick(View view) {

        int bufferSize;
        bufferSize = (int) ((getSamplingRate() * Float.parseFloat(frameSize.getText().toString()))/(2*1000));

        if(storeFeaturesSwitch.isChecked()){
            fileName = folderName + new SimpleDateFormat("yyyy_MM_dd_HH_mm_ss").format(new Date()) + ".txt";
            Log.d("Filename",fileName);
        }
        // Get the device's sample rate and buffer size to enable low-latency Android audio output, if available.

        if (Build.VERSION.SDK_INT >= 17) {
            //AudioManager audioManager = (AudioManager) this.getSystemService(Context.AUDIO_SERVICE);
            samplerateString = Integer.toString(getSamplingRate());//audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE);
            buffersizeString = Integer.toString(bufferSize); //audioManager.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER);
        }

        if (samplerateString == null) samplerateString = "44100";
        if (buffersizeString == null) buffersizeString = "512";

        System.loadLibrary("FrequencyDomain");
        String path = folderName;
        Log.d("Files", "Path: " + path);
        File directory = new File(path);
        final File[] files = directory.listFiles();
        Log.d("Files", "Size: "+ files.length);
        List<String> filenames = new ArrayList<String>();
        for (int i = 0; i < files.length; i++)
        {
            Log.d("Files", "FileName: " + getExtensionOfFile(files[i].getName()));

            if (getExtensionOfFile(files[i].getName()).equals("wav")){
                filenames.add(files[i].getName());
            }

        }

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle("Choose Audio File:");
        final CharSequence[] charSequenceItems = filenames.toArray(new CharSequence[filenames.size()]);
        builder.setItems(charSequenceItems, new DialogInterface.OnClickListener() {
            public void onClick(DialogInterface dialog, int which) {
                Log.d("Files", String.valueOf(which));
                audioFileName = folderName + charSequenceItems[which];
                System.loadLibrary("FrequencyDomain");
                ReadFile(Integer.parseInt(samplerateString),
                        Integer.parseInt(buffersizeString),
                        Float.parseFloat(decisionRate.getText().toString()),
                        (float) (quietAdjustment.getProgress() - 10),
                        playAudioSwitch.isChecked(),
                        storeFeaturesSwitch.isChecked(),
                        fileName,
                        audioFileName, true);
                disableButtons();
                handler.postDelayed(r,1000);
            }
        });
        builder.show();
    }




    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            return true;
        }

        return super.onOptionsItemSelected(item);
    }

    Handler handler = new Handler();

    final Runnable r = new Runnable() {
        @Override
        public void run() {
            getTime();
            handler.postDelayed(this, 1000);
        }
    };

    private int getSamplingRate(){

        int value = samplingRate.getProgress();

        switch(value) {
            case 0:
                return 8000;
            case 1:
                return 11025;
            case 2:
                return 12000;
            case 3:
                return 16000;
            case 4:
                return 22050;
            case 5:
                return 24000;
            case 6:
                return 32000;
            case 7:
                return 44100;
            case 8:
                return 48000;
            default:
                return 16000;
        }
    }

    public static String getExtensionOfFile(String name)
    {
        String fileExtension="";

        // If fileName do not contain "." or starts with "." then it is not a valid file
        if(name.contains(".") && name.lastIndexOf(".")!= 0)
        {
            fileExtension=name.substring(name.lastIndexOf(".")+1);
        }

        return fileExtension;
    }


    private native void FrequencyDomain(int samplerate,
                                        int buffersize,
                                        float decisionRate,
                                        float quietThreshold,
                                        boolean playAudio,
                                        boolean storeFeatures,
                                        String fileName);
    private native void StopAudio(String fileName, String audioFile);
    private native float getExecutionTime();
    private native int getDetectedClass();
    private native float getdbPower();
    private native void ReadFile(int samplerate,
                                 int buffersize,
                                 float decisionRate,
                                 float quietThreshold,
                                 boolean playAudio,
                                 boolean storeFeatures,
                                 String fileName,
                                 String audioFileName, boolean readFromFileStatus);

    private native String getDetectedNoiseClassLabel();
    private native int getDetectedNoiseClass();
}
