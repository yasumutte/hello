s.quit;
s.boot;

(
var dir = thisProcess.nowExecutingPath.dirname;

~buf_snare = Buffer.read(s,
	(dir +/+ "/samples/RD_S_5.wav").standardizePath);
~buf_kick = Buffer.read(s,
	(dir +/+ "/samples/RD_K_6.wav").standardizePath);
~buf_hihat1 = Buffer.read(s,
	(dir +/+ "/samples/Hit_Fully_Closed_2.wav").standardizePath);
)

(
SynthDef(\supersaw, {
	arg detuneRatio = 0.1, tempoRatio = 1, freq = 440, gate = 1,
	atk = 0.01, dec = 2, sus = 0.25, rel = 0.05, filtRel = 2,
	amp = 0.1, pan = 0.0, out = 0;
	var sig, env, freqs, detunes, ratios, phases, sigM, sigS;

	ratios = (([-37, 0, 31]/1000)*12).midiratio.sqrt;
	detunes = 1 + (detuneRatio * (ratios - 1));
	phases = [Rand(0, 1), 0, Rand(0, 1)];

	freqs = detunes * freq;

	env = EnvGen.kr(Env.adsr(atk, dec, sus, rel), gate, doneAction: 2);
	sig = Splay.ar(SawDPW.ar(freqs, phases), 0.75, 1, 0);
	// sig = DFM1.ar(sig, EnvGen.kr(Env.perc(0.015, filtRel), 1, 12800, 200), 0.0, 1) * amp;
	sig = DFM1.ar(sig, EnvGen.kr(Env.perc(0.015, filtRel), 1, 12800, 200), 0.0, 1) * amp;
	sig = HPF.ar(sig, 40).clip2(1.0);
	sig = BPeakEQ.ar(sig, 240, 0.3, -2);
	sig = BLowShelf.ar(sig, 200, 1, -3);
	sig = LPF.ar(sig, 14000);
	sig = sig * env;

	sigM = sig[0] + sig[1];
	sigS = sig[0] - sig[1];
	sigS = HPF.ar(sigS, 300).clip2(1.0);

	sig = [(sigM + sigS), (sigM - sigS)]*0.5;

	Out.ar(out, sig);
}).add;

SynthDef(\sampler_stereo, {
	arg bufnum, amp = 1.0,
	atk = 0, gate = 1, rate = 1.25, out = 0;

	var sig, env;
	env = EnvGen.kr(Env.adsr(atk, 1, 1, 0.05), gate, doneAction: 2);
	sig = PlayBuf.ar(2, bufnum, rate, 1);
//	sig = HPF.ar(sig, 80);
	sig = sig * amp;
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\sampler_stereo_locut, {
	arg bufnum, amp = 1.0,
	atk = 0, gate = 1, rate = 1.25, out = 0;

	var sig, env;
	env = EnvGen.kr(Env.adsr(atk, 1, 1, 0.05), gate, doneAction: 2);
	sig = PlayBuf.ar(2, bufnum, rate, 1);
	sig = HPF.ar(sig, 80);
	sig = sig * amp;
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\sampler_stereo_hh, {
	arg bufnum, amp = 1.0,
	atk = 0, gate = 1, rate = 1.25, out = 0;

	var sig, env;
	env = EnvGen.kr(Env.adsr(atk, 1, 1, 0.05), gate, doneAction: 2);
	sig = PlayBuf.ar(2, bufnum, rate, 1);
	sig = Splay.ar(sig, 0.5, 1);
	sig = HPF.ar(sig, 200).clip2(1.0);
	sig = sig * amp;
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\pul, {
	arg freq = 440, amp = 0.1, gate = 1, pw = 0.5, pan = 0, out = 0;

	var sig, env;

	env = EnvGen.kr(Env.adsr(0.01, 1, 1, 0.05), gate, doneAction: 2);
	sig = PulseDPW.ar(freq, pw, amp);
	sig = Pan2.ar(sig, pan);
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\subbass, {
	arg freq = 440, amp = 0.1, gate = 1, pw = 0.5, pan = 0, out = 0;

	var sig, env;

	freq = Lag2.kr(freq, 0.05);
	freq = freq*EnvGen.kr(Env.perc(0.001, 0.05), 1, 2, 1);

	env = EnvGen.kr(Env.adsr(0.01, 16, 0, 0.05), gate, doneAction: 2);
	sig = SinOsc.ar(freq, 0, amp);
	sig = Pan2.ar(sig, pan);
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\pulrep, {
	arg freq = 440, amp = 0.1, pw = 0.5,
	tempoRatio = 1, pan = 0, panPhase = 0, out = 0;

	var sig, env;

	freq = freq * Demand.kr(Impulse.kr(6*tempoRatio), 0, Dseq([
		0, 5, 10, 15,
	], inf)).midiratio;

	env = EnvGen.kr(Env.perc(0.01, 2.5), doneAction: 2);
	sig = PulseDPW.ar(freq, pw, amp);
	sig = Pan2.ar(sig, SinOsc.kr(0.5, panPhase).range(-0.5, 0.5));
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\puler, {
	arg freq = 440, amp = 0.1, pw = 0.5,
	tempoRatio = 1, pan = 0, panPhase = 0, out = 0;

	var sig, env;

	freq = Lag2.kr(freq, 0.1);
	freq = freq * SinOsc.kr(1).range(0.5, 1.5);

	env = EnvGen.kr(Env.perc(0.01, 2.5), doneAction: 2);
	sig = PulseDPW.ar(freq, pw, amp);
	sig = Pan2.ar(sig, SinOsc.kr(1).range(-0.5, 0.5));
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\chirp, {
	arg freq = 440, amp = 0.1, pw = 0.5,
	tempoRatio = 1, pan = 0, panPhase = 0, out = 0;

	var sig, env;

	freq = Lag2.kr(freq, 0.1);
	freq = freq * Line.kr(8, 1, 0.1*tempoRatio);

	env = EnvGen.kr(Env.perc(0.01, 0.1), doneAction: 2);
	sig = PulseDPW.ar(freq, pw, amp);
	sig = Pan2.ar(sig, pan);
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\riser, {
	arg amp = 0.1, gate = 1, tempoRatio = 1, out = 0;
	var sig, env;

	env = EnvGen.kr(Env.asr(0.01, 1, 0.05), gate, doneAction: 2);
	sig = PulseDPW.ar(SinOsc.kr(Line.kr(4, 16, 4*tempoRatio.reciprocal)).range(
		Line.kr(0.99, 0.5, 4*tempoRatio.reciprocal),
		Line.kr(1.01, 1.5, 4*tempoRatio.reciprocal)
	)*Line.kr(200, 2400, 8*tempoRatio.reciprocal), 0.5, amp);
	// sig = Pan2.ar(sig, SinOsc.kr(Line.kr(1, 8, 8*tempoRatio.reciprocal)).range(-0.5, 0.5));
	sig = Pan2.ar(sig, 0);
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\bass, {
	arg freq = 440, amp = 0.1, gate = 1,
	cutoff = 2000, feedbackRatio = 0.1,
	amount = 0.1, pan = 0, out = 0;

	var sig, env;

	freq = Lag2.kr(freq, 0.05);

	env = EnvGen.kr(Env.adsr(0.01, 16, 0, 0.05), gate, doneAction: 2);
	sig = SinOsc.ar(freq, SinOscFB.ar(freq*2, feedbackRatio*2pi, amount*2pi), amp);
	sig = LPF.ar(sig, cutoff);
	sig = BPeakEQ.ar(sig, 400, 0.5, -3);
	sig = Pan2.ar(sig, pan);
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\noise, {
	arg amp = 0.1, gate = 1, coef = 7,
	atk = 0.01, dec = 1, sus = 1, rel = 0.05,
	tempoRatio = 1, out = 0;

	var sig, env;
	env = EnvGen.kr(Env.adsr(atk, dec, sus, rel), gate,
		timeScale: tempoRatio.reciprocal, doneAction: 2);
	sig = StandardL.ar(SampleRate.ir/coef, {LFNoise1.kr(8).range(3,4)}!2);
	sig = Splay.ar(sig, 0.25) * amp;
	sig = HPF.ar(sig, 140);
	sig = sig * env;

	Out.ar(out, sig);
}).add;

SynthDef(\master, {
	arg amp = 1, gate = 1, out = 0;
	var sig, wet;
	sig = In.ar(out, 2);
	sig = sig * 1.5;
	sig = LPF.ar(sig, 18000);
	sig = BPeakEQ.ar(sig, 400, 0.3, -1);
	// sig = BHiShelf.ar(sig, 16000, 1, -6);
	sig = Limiter.ar(sig, 0.99);
	sig = sig * amp * EnvGen.kr(Env([1, 1, 0], [1, 1], 'lin', 1), gate, doneAction: 2);
	ReplaceOut.ar(out, sig);
}).add;
)

(
~tempoRatio = 192/60;
~root = 6;

~pattern1_kick = Pbind(
	\instrument, \sampler_stereo,
	\amp, 0.95,
	\bufnum, ~buf_kick,
	\legato, Pseq([
		0.125, 0.99, 0.25, 0.25, 0.99,
	], inf)*0.5,
	\dur, Pseq([
		2, Rest(1.5), 1, 1, Rest(2.5),
	], inf),
);

~pattern2_kick = Pbind(
	\instrument, \sampler_stereo,
	\amp, 0.85,
	\bufnum, ~buf_kick,
	\legato, Pseq([
		0.25*(1/1.5),
		0.25*(1/1.5),
		0.25,
	], inf)*0.5,
	\dur, Pseq([
		1.5, 1.5, 1,
	], inf),
);

~pattern1_snare = Pbind(
	\instrument, \sampler_stereo,
	\amp, Pseq([
		0.95, Pseq(5.collect((_*0.5pi/5).sin))*0.5, 0.95,
	], inf) * 0.8,
	\bufnum, ~buf_snare,
	\atk, Pseq([
		0.0, Pn(0.1, 5), 0.0,
	], inf),
	\legato, Pseq([
		Pseq([
			0.99, Pn(1, 5), 0.1,
		], 7),
		0.99, Pn(1, 5), 2/1.5,
	], inf),
	\dur, Pseq([
		Pseq([Rest(1.5), Pn(Rest(0.1), 5), 2]),
		Pseq([Rest(1.5), Pn(Rest(0.1), 5), 2]),
		Pseq([Rest(1.5), Pn(Rest(0.1), 5), 2]),
		Pseq([Rest(1.8), Pseq([0.2, 5.collect((_+1)**2), 1].convertRhythm), 2]),
		Pseq([Rest(1.5), Pn(Rest(0.1), 5), 2]),
		Pseq([Rest(1.5), Pn(Rest(0.1), 5), 2]),
		Pseq([Rest(1.5), Pn(Rest(0.1), 5), 2]),
		Pseq([Rest(2.2), Pseq([0.3, 5.collect((_+1)**2), 1].convertRhythm), 1.5]),
	], inf),
);

~pattern2_snare = Pbind(
	\instrument, \sampler_stereo,
	\amp, Pseq([
		0.25, Pseq(7.collect((_*0.5pi/7).sin))*0.75,
	], inf) * 0.8,
	\bufnum, ~buf_snare,
	\atk, Pseq([
		0, Pseq(7.collect((_*0.5/7).sin).reverse)+0.05,
		0, Pseq(7.collect((_*0.5/7).sin).reverse)+0.05,
		0, Pseq(7.collect((_*0.5/7).sin)),
	], inf),
	\legato, Pseq([
		0.99, Pn(1, 7),
	], inf),
	\dur, Pseq([
		Pseq([Rest(0.5), Pseq([1.0, 7.collect((_+1)**2), 1].convertRhythm)]),
		Pseq([Rest(0.5), Pseq([1.0, 7.collect((_+1)**2), 1].convertRhythm)]),
		Pseq([Rest(0.2), Pseq([0.8, 7.collect((_+1)**2), 1].convertRhythm)]),
	], inf),
	\timingOffset, -0.2,
);

~pattern1_hihat = Pbind(
	\instrument, \sampler_stereo_hh,
	\amp, 0.685,
	\bufnum, ~buf_hihat1,
	\rate, 1,
	\atk, Pseq([0.01, 0.05], inf),
	\legato, 0.08,
	\dur, Pseq([
		Rest(1),
		Pn(1, 13), Rest(1), 1,
		Pn(1, 14), Rest(1), Rest(1),
	], inf),
);

~pattern1_chord = Pbind(
	\instrument, \supersaw,
	\amp, 0.165*0.85*0.85,
	\atk, 0.015,
	\detuneRatio, 0.1125,
	\root, ~root,
	\scale, Scale.chromatic,
	\sus, 0.75,
	\tempoRatio, ~tempoRatio,
	\legato, Pseq([
		Pseq([1, 0.8, 0.2, 0.3, 0.8]),
	], inf),
	\dur, Pseq([
		Pseq([3.5, 0.5, 1.5, 1.0, 1.5]),
	], inf),
	\degree, Pseq([
		Pn([-12, -5, -2, 3], 5),
		Pn([-12, -5, -2, 3], 5),
		Pn([-12, -5, -2, 3], 5),
		Pn([-19, -9, -4, 0], 3),
		Pn([-17, -7, -2, 2], 2),
	], inf),
);

~pattern2_chord = Pbind(
	\instrument, \supersaw,
	\amp, 0.165*0.85*0.85,
	\atk, 0.015,
	\sus, 0.75,
	\detuneRatio, 0.1125,
	\root, ~root,
	\scale, Scale.chromatic,
	\tempoRatio, ~tempoRatio,
	\legato, Pseq([
		Pseq([0.9, 0.9, 0.7]),
	], inf),
	\dur, Pseq([
		Pseq([1.5, 1.5, 1]),
	], inf),
	\degree, Pseq([
		Pn([-16, -9, -5, 0], 3),
		Pn([-14, -7, -4, 2], 3),
		Pn([-17, -10, -7, -2], 3),
		Pn([-12, -5, -2, 3], 2),
		Pn([-17, -10, -7, -2], 1),

		Pn([-16, -9, -5, 0], 3),
		Pn([-14, -7, -4, 2], 3),
		Pn([-12, -5, -2, 3], 3),
		Pn([-12, -5, -2, 3], 2),
		Pn([-17, -10, -7, -2], 1),

		Pn([-16, -9, -5, 0], 3),
		Pn([-14, -7, -4, 2], 3),
		Pn([-17, -10, -7, -1], 1),
		Pn([-17, -10, -7, 0], 1),
		Pn([-17, -10, -7, 2], 1),
		Pn([-12, -5, -2, 3], 2),
		Pn([-17, -10, -7, -2], 1),

		Pn([-16, -9, -5, 0], 3),
		Pn([-14, -7, -4, 2], 3),
		// Pn([-14, -7, -2, 2]+1, 3),
		// Pn([-14, -7, -2, 2]+3, 3),
	], inf),
);

~pattern1_pul = Pbind(
	\instrument, \pul,
	\amp, 0.15*1.125,
	\root, ~root-12,
	\scale, Scale.chromatic,
	\dur, 0.25*2,
	\pan, 0,//Pwhite(-0.25, 0.25, inf),
	\legato, Pseq([0.5, 0.25], inf),
	\degree, Pseq([
		Prand([0, 5, 7, 10]) + Prand([0, 12]),
	], inf),
);

~pattern2_pul = Pbind(
	\instrument, \pul,
	\amp, 0.08*1.125,
	\root, ~root+12,
	\scale, Scale.chromatic,
	\dur, 0.25,
	\pan, 0.75,
	\pw, 0.25,
	\legato, Pseq([0.5, 0.25], inf),
	\degree, Pseq([
		Pseq([17, 10, 5, 0, 10, 5, 0, 5, 0]),
	], inf),
);

~pattern3_pul = Pbind(
	\instrument, \pul,
	\amp, 0.08*1.125,
	\root, ~root+12,
	\scale, Scale.chromatic,
	\dur, 0.25,
	\pan, -0.75,
	\pw, 0.25,
	\legato, Pseq([0.5, 0.25], inf),
	\degree, Pseq([
		Pseq([5, 7, 3, 5, 7, 3]),
	], inf),
);

~pattern1_pulrep = Pbind(
	\instrument, \pulrep,
	\amp, 0.15*1.25,
	\root, ~root,
	\panPhase, Pseq([0.5, 0.5pi, 0.5, 1.5pi], inf),
	\dur, Pseq([Rest(0.5), 15.5], inf),
	\degree, 0,
	\tempoRatio, ~tempoRatio,
);

~pattern1_bass = Pbind(
	\instrument, \bass,
	\amp, 0.175*1.075,
	\root, ~root-24,
	\scale, Scale.chromatic,
	\tempoRatio, ~tempoRatio,
	\legato, Pseq([
		Pseq([2.5/3.5, 0.8, 0.2, 0.3, 0.8]),
	], inf),
	\dur, Pseq([
		Pseq([3.5, 0.5, 1.5, 1.0, 1.5]),
	], inf),
	\degree, Pseq([
		Pn(0, 5),
		Pn(0, 5),
		Pn(0, 5),
		Pn(-7, 3),
		Pn(-5, 2),
	], inf),
);

~pattern1_bass_x = Pbind(
	\instrument, \bass,
	\amp, 0.175*1.075,
	\root, ~root-24,
	\scale, Scale.chromatic,
	\tempoRatio, ~tempoRatio,
	\legato, Pseq([
		Pseq([2.5/3.5, 0.8, 0.2, 0.3, 0.8]),
	], inf),
	\dur, Pseq([
		Pseq([3.5, 0.5, 1.5, 1.0, 1.5]),
		Pseq([3.5, 0.5, 1.5, Rest(1.0), Rest(1.5)]),
		Pseq([3.5, 0.5, 1.5, 1.0, 1.5]),
		Pseq([3.5, 0.5, 1.5, 1.0, 1.5]),
	], inf),
	\degree, Pseq([
		Pn(0, 5),
		Pn(0, 5),
		Pn(0, 5),
		Pn(-7, 3),
		Pn(-5, 2),
	], inf),
);

~pattern2_bass = Pbind(
	\instrument, \bass,
	\amp, 0.215,
	\root, ~root-24,
	\scale, Scale.chromatic,
	\tempoRatio, ~tempoRatio,
	\legato, Pseq([
		Pseq([1.0/1.5, 1.0/1.5, 0.75]),
	], inf),
	\dur, Pseq([
		Pseq([1.5, 1.5, 1]),
	], inf),
	\amount, 0.02,
	\degree, Pseq([
		Pn(-4, 3),
		Pn(-2, 3),
		Pn(-5, 3),
		Pn( 0, 2),
		Pn(-5, 1),

		Pn(-4, 3),
		Pn(-2, 3),
		Pn( 0, 3),
		Pn( 0, 2),
		Pn(-5, 1),

		Pn(-4, 3),
		Pn(-2, 3),
		Pn(-5, 3),
		Pn( 0, 2),
		Pn(-5, 1),

		Pn(-4, 3),
		Pn(-2, 3),
	], inf),
);

~pattern2_bass_x = Pbind(
	\instrument, \bass,
	\amp, 0.2,
	\root, ~root-24,
	\scale, Scale.chromatic,
	\tempoRatio, ~tempoRatio,
	\legato, Pseq([
		0.8
	], inf),
	\dur, 0.25,
	\amount, 0.15,
	\feedbackRatio, 0.25,
	\cutoff, 10000,
	\degree, Pseq([
		Pseq([Rest(), Rest(), -4, -4+7], 4),
		Pseq([Rest(), Rest(), -2, -2+7], 4),
		Pseq([Rest(), Rest(), -5, -5+7], 4),
		Pseq([Rest(), Rest(), -0, -0+7], 2),
		Pseq([Rest(), Rest(), -5, -5+7], 2),

		Pseq([Rest(), Rest(), -4, -4+7], 4),
		Pseq([Rest(), Rest(), -2, -2+7], 4),
		Pseq([Rest(), Rest(), -0, -0+7], 4),
		Pseq([Rest(), Rest(), -0, -0+7], 2),
		Pseq([Rest(), Rest(), -5, -5+7], 2),

		Pseq([Rest(), Rest(), -4, -4+7], 4),
		Pseq([Rest(), Rest(), -2, -2+7], 4),
		Pseq([Rest(), Rest(), -5, -5+7], 4),
		Pseq([Rest(), Rest(), -0, -0+7], 2),
		Pseq([Rest(), Rest(), -5, -5+7], 2),

		Pseq([Rest(), Rest(), -4, -4+7], 4),
		Pseq([Rest(), Rest(), -2, -2+7], 4),
	], inf),
);

~pattern1_pul_bass = Pbind(
	\instrument, \subbass,
	\amp, 0.435,
	\root, ~root-36,
	\scale, Scale.chromatic,
	// \degree, Pseq([
	// 	0, 0, 0, 5,
	// ], inf),
	// \legato, Pseq([
	// 	0.75,
	// ], inf),
	// \dur, Pseq([
	// 	8,
	// ], inf),
	\legato, Pseq([
		Pseq([1/3.5, 1/3.5]),
	], inf),
	\dur, Pseq([
		Pseq([3.5, 4.5]),
	], inf),
	\degree, Pseq([
		Pn(0, 2),
		Pn(0, 2),
		Pn(0, 2),
		Pn(5, 2),
	], inf),
	// \timingOffset, Pseq([
	// 	0.1,
	// ], inf),
);

~pattern1_pul_bass_x = PmonoArtic(
	\subbass,
	\amp, 0.435,
	\root, ~root-36,
	\scale, Scale.chromatic,
	// \degree, Pseq([
	// 	0, 0, 0, 5,
	// ], inf),
	// \legato, Pseq([
	// 	0.75,
	// ], inf),
	// \dur, Pseq([
	// 	8,
	// ], inf),
	\legato, Pseq([
		Pseq([1, 0.9]),
	], 1),
	\dur, Pseq([
		Pseq([1.5, 1.5]),
	], 1),
	\degree, Pseq([
		Pseq([12, 7]),
	], 1),
	\timingOffset, 0,
);

~pattern2_pul_bass = PmonoArtic(
	\subbass,
	\amp, 0.435,
	\root, ~root-36,
	\scale, Scale.chromatic,
	\degree, Pstutter(1, Pseq([
		-4, -2, Pseq([12-5, -5]), 0,
		Pseq([-4, -4+7]), Pseq([-2, -2+7]), Pseq([12, 0]), 0,
		-4, -2, Pseq([12-5, -5]), 0,
		-4, -2,
	], inf)),
	\legato, Pseq([
		0.75, 0.75, 1, 0.6, 0.75,
		Pseq([1, 0.6], 3), 0.75,
		0.75, 0.75, 1, 0.6, 0.75,
		0.75, 0.75,
	], inf),
	\dur, Pseq([
		4, 4, 1.5, 2.5, 4,
		Pseq([1.5, 2.5], 3), 4,
		4, 4, 1.5, 2.5, 4,
		4, 4,
	], inf),
	// \timingOffset, Pseq([
	// 	0.1, 0.1, 0, 0, 0.1,
	// 	Pseq([0.1, 0], 2), 0, 0, 0.1,
	// 	0.1, 0.1, 0, 0, 0.1,
	// 	0.1, 0.1,
	// ], inf),
);

~pattern3_pul_bass = Pbind(
	\instrument, \subbass,
	\amp, 0.435,
	\root, ~root-36,
	\scale, Scale.chromatic,
	\degree, Pseq([
		0, 0, 0, 5,
	], inf),
	\legato, Pseq([
		0.75,
	], inf),
	\dur, Pseq([
		Rest(8), 8, Rest(8), 8,
	], inf),
	// \timingOffset, Pseq([
	// 	0.1,
	// ], inf),
);

~pattern4_pul_bass_fadein = Pmono(
	\subbass,
	\amp, Env([0, 0.435], [7]),
	\root, ~root-36,
	\scale, Scale.chromatic,
	\degree, Pseq([
		Pn(-4, 80),
		Pn(-2, 80),
	], inf),
	\legato, Pseq([
		0.75,
	], inf),
	\dur, Pseq([
		0.05,
	], inf),
	\timingOffset, Pseq([
		0.1,
	], inf),
);

~pattern1_puler = PmonoArtic(
	\puler,
	\amp, 0.175,
	\pw, 0.25,
	\root, 6,
	\legato, Pseq([
		1, 1, 1, 0.25,
		1, 1, 1, 0.25,
	]),
	\dur, Pseq([
		0.25, 0.25, 0.25, 0.25,
		0.25, 0.25, 0.25, 0.25,
	])*2,
	\degree, Pseq([
		15, 10, 5, 0,
		10, 5, 0, -2,
	]),
);

~pattern1_noise = Pbind(
	\instrument, \noise,
	\amp, Pseq([0.1, 0.125, 0.15]),
	\atk, 0.01,
	\dur, Pseq([8, 8, 8], 1),
	\legato, 1,
	\tempoRatio, ~tempoRatio,
);

~pattern2_noise = Pbind(
	\instrument, \noise,
	\amp, 0.25*1.3,
	\atk, 0.01,
	\dur, 0.5,
	\legato, Pn(1, 2),
	\coef, Pseq([7, 6], 1),
	\tempoRatio, ~tempoRatio,
);

~pattern1_pul_insane = Pbind(
	\instrument, \pul,
	\amp, Env([0, 0.35]*0.85, [8]),
	\root, ~root+0,
	\legato, 0.25,
	\scale, Scale.chromatic,
	\dur, Prand((1/[1,2,3,4,5,6,7,8]), inf),
	\pan, Pwhite(-0.5, 0.5, inf),
	\pw, 0.1,
);

~pattern2_pul_insane = Pbind(
	\instrument, \pul,
	\amp, Env([0, 0.33]*0.85, [8]),
	\root, ~root+12,
	\legato, 0.25,
	\scale, Scale.chromatic,
	\dur, Prand((1/[1,2,3,4,5,6,7,8]), inf),
	\pan, Pwhite(-0.5, 0.5, inf),
	\pw, 0.1,
	\degree, 7,
);

~pattern3_pul_insane = Pbind(
	\instrument, \pul,
	\amp, Env([0, 0.32]*0.85, [8]),
	\root, ~root+12,
	\legato, 0.25,
	\scale, Scale.chromatic,
	\dur, Prand((1/[1,2,3,4,5,6,7,8]), inf),
	\pan, Pwhite(-0.5, 0.5, inf),
	\pw, 0.25,
	\degree, 0,
);

~pattern4_pul_insane = Pbind(
	\instrument, \pul,
	\amp, Env([0, 0.4]*0.85, [8]),
	\root, ~root+0,
	\legato, 0.25,
	\scale, Scale.chromatic,
	\dur, Pseq([8, 63.collect((_+1)**2).reverse, 1].convertRhythm),
	\pan, Pwhite(-0.5, 0.5, inf),
	\pw, 0.5,
	\degree, Prand([0, 5, 7], inf) + Prand([-12, 0, 12], inf),
);

~song = Ptpar([
	0, Psync(Ppar([
		Pbindf(~pattern1_chord,
			\amp, Pseq([0.165*0.85*0.9, Pn(0.165*0.85*0.85)])),
		~pattern1_pul,
		~pattern1_pulrep,
		Pseq([
			Event.silent(64),
			Event.silent(3.5), ~pattern1_puler,
		]),
		~pattern1_kick,
		~pattern1_snare,
		~pattern1_hihat,
		~pattern1_bass,
	]), 1, 128),
	128, Pbind(
		\instrument, \riser,
		\amp, 0.175,
		\legato, 1,
		\dur, Pseq([4], 1),
		\tempoRatio, ~tempoRatio,
	),
	132, Psync(Ppar([
		Pbindf(~pattern1_pul, \dur, 0.25),
		~pattern2_pul,
		~pattern3_pul,
		Pbindf(~pattern2_kick, \instrument, \sampler_stereo_locut),
		~pattern2_bass,
		~pattern2_snare,
		~pattern2_chord,
		Pseq([
			Event.silent(32),
			~pattern1_noise,
		]),
		Pbind(
			\type, \rest,
			\dur, Pseq([55.9, 0.1]),
			\tempo, ~tempoRatio*Pseq([0.875, 1]),
		),
	]), 1, 64-8),
	188, Psync(Ppar([
		~pattern1_chord,
		~pattern1_pul,
		~pattern1_pulrep,
		Pseq([
			Event.silent(64),
			Event.silent(3.5), ~pattern1_puler,
		]),
		~pattern2_noise,
		~pattern1_kick,
		~pattern1_snare,
		~pattern1_hihat,
		Pseq([
			Psync(~pattern1_bass, 1, 32),
			Psync(~pattern1_bass, 1, 32),
			Psync(~pattern1_bass_x, 1, 32),
			Psync(~pattern1_bass, 1, 32),
		]),
		Pseq([
			Event.silent(64),
			Event.silent(8 + 5), ~pattern1_pul_bass_x,
			Event.silent(32),
		]),
	]), 1, 128),
	316, Pbindf(
		~pattern1_pul,
		\amp, Env([0.2, 0.175]*1.25, [4]),
		\legato, 0.5,
		\dur, Pseq([4, 21.collect((_+1)*2).reverse, 1].convertRhythm),
	),
	320, Psync(Ppar([
		~pattern2_chord,
		Pbindf(~pattern1_pul, \dur, 0.25),
		~pattern2_pul,
		~pattern3_pul,
		Pbindf(~pattern2_kick, \instrument, \sampler_stereo_locut),
		~pattern2_bass,
		~pattern2_snare,
		Pseq([
			Event.silent(32),
			~pattern1_noise,
		]),
		Pseq([
			Event.silent(48),
			Ppar([
				~pattern1_pul_insane,
				~pattern2_pul_insane,
				~pattern3_pul_insane,
				~pattern4_pul_insane,
			]),
		]),
		Pbind(
			\type, \rest,
			\dur, Pseq([55.9, 0.1]),
			\tempo, ~tempoRatio*Pseq([0.875, 1]),
		),
	]), 1, 64-8),
	376, Psync(Ppar([
		Pseq([
			Psync(~pattern1_chord, 1, 4),
			Event.silent(12),
		], 4),
		~pattern1_pul,
		~pattern1_pulrep,
		~pattern3_pul_bass,
		Pbindf(~pattern2_noise, \amp, 0.25*1.35),
		Pseq([
			Psync(~pattern1_kick, 1, 8),
			Psync(
				Pbindf(~pattern1_kick, \instrument, \sampler_stereo_locut),
				1, 8),
		], 4),
		Psync(~pattern1_hihat, 1, 56),
		Pseq([
			Psync(~pattern1_bass, 1, 4),
			Event.silent(12),
		], 4),
		Pseq([
			Pseq([
				Psync(~pattern1_snare, 1, 16),
			], 2),
			Psync(~pattern1_snare, 1, 24),
			Event.silent(8),
		], 2),
	]), 1, 32*2),
]);

Pfx(
	Pseq([
		Psync(Pbindf(~pattern1_snare,
			\rate, 1.5,
			\amp, 1,
			\legato, 0.075
		), 1, 4),
		~song
	]),
	\master,
	\amp, 1,
).play(TempoClock(~tempoRatio));
)
