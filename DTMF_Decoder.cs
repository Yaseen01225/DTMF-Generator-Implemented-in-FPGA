
void Main()
{
	// ============================================================
	// USER SETTINGS
	// ============================================================

	string file = @"D:\dtmf_audio.pcm";
	

	int sampleRate = 32000;

	// Supported: TextInteger or Pcm16
	string inputFormat = "TextInteger";

	int channels = 1;

	// Used only for Pcm16: LittleEndian or BigEndian
	string byteOrder = "LittleEndian";

	// ============================================================
	// READ PCM FILE
	// ============================================================

	if (!File.Exists(file))
	{
		("File not found: " + file).Dump();
		return;
	}

	double[] samples;

	try
	{
		samples = ReadPcm(file, inputFormat, channels, byteOrder);
	}
	catch (Exception ex)
	{
		("PCM reading error: " + ex.Message).Dump();
		return;
	}

	if (samples.Length == 0)
	{
		"No PCM samples found.".Dump();
		return;
	}

	// ============================================================
	// PCM FILE PARAMETERS
	// ============================================================

	double minimum = samples.Min();
	double maximum = samples.Max();

	double peak = Math.Max(
		Math.Abs(minimum), Math.Abs(maximum));

	double rms = Math.Sqrt(
		samples.Average(x => x * x));

	double dcOffset = samples.Average();

	double duration = (double)samples.Length / sampleRate;

	"========== PCM FILE PARAMETERS ==========".Dump();

	new
	{
		FileName = Path.GetFileName(file),
		FileSizeBytes = new FileInfo(file).Length,
		InputFormat = inputFormat,
		SampleRateHz = sampleRate,
		Channels = channels,
		SamplesAfterChannelMixing = samples.Length,
		DurationSeconds = Math.Round(duration, 4),
		MinimumSample = Math.Round(minimum, 2),
		MaximumSample = Math.Round(maximum, 2),
		PeakAmplitude = Math.Round(peak, 2),
		PeakPercent = Math.Round(peak / 32768.0 * 100, 2),
		RMSAmplitude = Math.Round(rms, 2),
		RMSPercent = Math.Round(rms / 32768.0 * 100, 2),
		DCOffset = Math.Round(dcOffset, 2),
		ZeroSamples = samples.Count(x => x == 0)
	}.Dump();

	// ============================================================
	// AUTOMATIC TONE DETECTION
	// ============================================================

	List<Segment> segments = DetectTones(samples, sampleRate);

	"========== DETECTED TONE REGIONS ==========".Dump();

	segments.Select((s, i) => new
	{
		ToneNumber = i + 1,
		StartTimeMs = Math.Round(
			s.Start * 1000.0 / sampleRate, 2),
		EndTimeMs = Math.Round(
			s.End * 1000.0 / sampleRate, 2),
		DurationMs = Math.Round(
			(s.End - s.Start) * 1000.0 / sampleRate, 2)
	}).Dump();

	// ============================================================
	// DTMF FREQUENCY TABLE
	// ============================================================

	int[] lowFrequencies = { 697, 770, 852, 941 };
	int[] highFrequencies = { 1209, 1336, 1477 };

	string[,] digits =
	{
		{ "1", "2", "3" },
		{ "4", "5", "6" },
		{ "7", "8", "9" },
		{ "*", "0", "#" }
	};

	// ============================================================
	// DECODE EACH TONE
	// ============================================================

	List<object> results = new List<object>();
	List<char> decodedDigits = new List<char>();

	int digitNumber = 0;

	foreach (Segment segment in segments)
	{
		int length = segment.End - segment.Start;

		// Ignore regions that are too short for reliable detection.
		int minimumLength = (int)(sampleRate * 0.040);

		if (length < minimumLength)
			continue;

		// Analyze the central portion of the tone.
		int analysisLength = Math.Min(
			length, (int)(sampleRate * 0.070));

		int analysisStart =
			segment.Start + (length - analysisLength) / 2;

		double[] lowPowers = new double[4];
		double[] highPowers = new double[3];

		double[] lowMeasured = new double[4];
		double[] highMeasured = new double[3];

		// Find the strongest low-group frequency.
		for (int i = 0; i < 4; i++)
		{
			lowPowers[i] = FindBestFrequency(
				samples,
				analysisStart,
				analysisLength,
				sampleRate,
				lowFrequencies[i],
				out lowMeasured[i]);
		}

		// Find the strongest high-group frequency.
		for (int i = 0; i < 3; i++)
		{
			highPowers[i] = FindBestFrequency(
				samples,
				analysisStart,
				analysisLength,
				sampleRate,
				highFrequencies[i],
				out highMeasured[i]);
		}

		int lowIndex = Array.IndexOf(
			lowPowers, lowPowers.Max());

		int highIndex = Array.IndexOf(
			highPowers, highPowers.Max());

		int nominalLow = lowFrequencies[lowIndex];
		int nominalHigh = highFrequencies[highIndex];

		string digit = digits[lowIndex, highIndex];

		digitNumber++;

		decodedDigits.Add(digit[0]);

		results.Add(new
		{
			DigitNumber = digitNumber,
			Digit = digit,

			LowFrequencyHz = Math.Round(
				lowMeasured[lowIndex], 1),

			HighFrequencyHz = Math.Round(
				highMeasured[highIndex], 1),

			NominalLowHz = nominalLow,
			NominalHighHz = nominalHigh,

			StartTimeMs = Math.Round(
				segment.Start * 1000.0 / sampleRate, 2),

			DurationMs = Math.Round(
				length * 1000.0 / sampleRate, 2),

			LowPower = Math.Round(
				lowPowers[lowIndex], 2),

			HighPower = Math.Round(
				highPowers[highIndex], 2)
		});
	}

	// ============================================================
	// FINAL RESULTS
	// ============================================================

	"========== DTMF DECODE RESULTS ==========".Dump();

	results.Dump();

	"========== DECODED SEQUENCE ==========".Dump();

	new string(decodedDigits.ToArray()).Dump();
}

// ================================================================
// PCM READER
// ================================================================

double[] ReadPcm(
	string file,
	string format,
	int channels,
	string byteOrder)
{
	if (channels < 1)
		throw new Exception("Invalid channel count.");

	List<double> values = new List<double>();

	if (format == "TextInteger")
	{
		foreach (string line in File.ReadAllLines(file))
		{
			if (string.IsNullOrWhiteSpace(line))
				continue;

			short value;

			if (!short.TryParse(
				line.Trim(),
				System.Globalization.NumberStyles.Integer,
				System.Globalization.CultureInfo.InvariantCulture,
				out value))
			{
				throw new Exception(
					"Invalid decimal PCM sample: " + line);
			}

			values.Add(value);
		}
	}
	else if (format == "Pcm16")
	{
		byte[] bytes = File.ReadAllBytes(file);

		if (bytes.Length % 2 != 0)
			throw new Exception("Invalid PCM16 byte count.");

		for (int i = 0; i < bytes.Length; i += 2)
		{
			short value;

			if (byteOrder == "LittleEndian")
			{
				value = (short)(
					bytes[i] | (bytes[i + 1] << 8));
			}
			else if (byteOrder == "BigEndian")
			{
				value = (short)(
					(bytes[i] << 8) | bytes[i + 1]);
			}
			else
			{
				throw new Exception("Invalid byte order.");
			}

			values.Add(value);
		}
	}
	else
	{
		throw new Exception(
			"Unsupported format. Use TextInteger or Pcm16.");
	}

	if (values.Count % channels != 0)
		throw new Exception("Incomplete audio channel frame.");

	// Convert interleaved channels to mono by averaging.
	int frameCount = values.Count / channels;

	double[] mono = new double[frameCount];

	for (int i = 0; i < frameCount; i++)
	{
		double sum = 0;

		for (int ch = 0; ch < channels; ch++)
			sum += values[i * channels + ch];

		mono[i] = sum / channels;
	}

	return mono;
}

// ================================================================
// TONE SEGMENT STRUCTURE
// ================================================================

class Segment
{
	public int Start;
	public int End;

	public Segment(int start, int end)
	{
		Start = start;
		End = end;
	}
}

// ================================================================
// AUTOMATIC TONE / SILENCE DETECTION
// ================================================================

List<Segment> DetectTones(double[] samples, int sampleRate)
{
	int frameSize = (int)(sampleRate * 0.020);
	int hopSize = (int)(sampleRate * 0.010);

	List<double> frameRms = new List<double>();

	for (int start = 0;
		 start + frameSize <= samples.Length;
		 start += hopSize)
	{
		double sum = 0;

		for (int i = 0; i < frameSize; i++)
		{
			double value = samples[start + i];
			sum += value * value;
		}

		frameRms.Add(Math.Sqrt(sum / frameSize));
	}

	if (frameRms.Count == 0)
		return new List<Segment>();

	double maximumRms = frameRms.Max();

	// Adaptive threshold: useful for different signal amplitudes.
	double threshold = Math.Max(100, maximumRms * 0.08);

	List<int> activeFrames = new List<int>();

	for (int i = 0; i < frameRms.Count; i++)
	{
		if (frameRms[i] >= threshold)
			activeFrames.Add(i);
	}

	List<Segment> segments = new List<Segment>();

	if (activeFrames.Count == 0)
		return segments;

	int firstFrame = activeFrames[0];
	int lastFrame = activeFrames[0];

	// Merge gaps of up to 20 ms.
	for (int i = 1; i < activeFrames.Count; i++)
	{
		int current = activeFrames[i];

		if (current - lastFrame <= 3)
		{
			lastFrame = current;
		}
		else
		{
			int start = firstFrame * hopSize;
			int end = Math.Min(
				samples.Length,
				lastFrame * hopSize + frameSize);

			segments.Add(new Segment(start, end));

			firstFrame = current;
			lastFrame = current;
		}
	}

	// Add the final region.
	segments.Add(new Segment(
		firstFrame * hopSize,
		Math.Min(samples.Length,
			lastFrame * hopSize + frameSize)));

	// Remove very short noise regions.
	int minimumLength = (int)(sampleRate * 0.040);

	return segments
		.Where(s => s.End - s.Start >= minimumLength)
		.ToList();
}

// ================================================================
// FREQUENCY SEARCH
// ================================================================

double FindBestFrequency(
	double[] samples,
	int start,
	int length,
	int sampleRate,
	int nominalFrequency,
	out double measuredFrequency)
{
	double bestPower = -1;
	measuredFrequency = nominalFrequency;

	// Search within +/- 1.5% of nominal DTMF frequency.
	int range = Math.Max(8,
		(int)(nominalFrequency * 0.015));

	int lower = nominalFrequency - range;
	int upper = nominalFrequency + range;

	for (int frequency = lower;
		 frequency <= upper;
		 frequency++)
	{
		double currentPower = GoertzelPower(
			samples, start, length,
			sampleRate, frequency);

		if (currentPower > bestPower)
		{
			bestPower = currentPower;
			measuredFrequency = frequency;
		}
	}

	return bestPower;
}

// ================================================================
// GOERTZEL FREQUENCY DETECTOR WITH HANN WINDOW
// ================================================================

double GoertzelPower(
	double[] samples,
	int start,
	int length,
	int sampleRate,
	double frequency)
{
	double coefficient = 2.0 * Math.Cos(
		2.0 * Math.PI * frequency / sampleRate);

	double s1 = 0;
	double s2 = 0;

	for (int i = 0; i < length; i++)
	{
		double window = 0.5 - 0.5 * Math.Cos(
			2.0 * Math.PI * i / (length - 1));

		double input = samples[start + i] * window;

		double s0 = input + coefficient * s1 - s2;

		s2 = s1;
		s1 = s0;
	}

	return s1 * s1 + s2 * s2 -
		   coefficient * s1 * s2;
}
