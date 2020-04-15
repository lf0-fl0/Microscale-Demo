/*
HI!
This is a little synthesizer to play around with a 31tet scale over a midipiano.
If you want to play it you need a MIDI keyboard or similar device connected to your computer.
The synth will listen to Midichannel "1" which should be standart.
There are no Control-Change messages used.

To run it:
Hoover your cursor over the code and use [cmd+enter](mac) / [ctl+enter](pc) simultaneously.
*/

(
s.waitForBoot{

	MIDIIn.connectAll;

	~noteArray = Array.newClear(127);
	~scaleSize = 31; //31
	~tuning = Tuning.et(pitchesPerOctave:~scaleSize);
	~asScale = Scale.chromatic(~tuning);


	SynthDef(\sineScale,{

			arg gate = 1, freq, amp, att, dec, sus,rel, pan, feed = 0.22;

			var osc, env, mix, fIn, fOut;

			fIn = LocalIn.ar(1).scope*feed;

			osc = Mix.ar( SinOsc.ar(freq*[1.003,5.001])*
				EnvGen.ar(Env.perc(0,[rel,1,2]*0.6),gate:1))*[1,0.5,0.2];

			osc = SinOsc.ar(freq+SinOsc.ar(Rand(0.1,2)),(fIn+osc)*amp.linlin(0.01,1,0.01,1.5));

			fOut = LocalOut.ar(Mix.ar(osc));

			osc = HPF.ar(osc,freq);

			osc = AmpComp.kr(freq,100)*osc;

			env = EnvGen.ar(Env.adsr(att,dec,sus,rel,amp,-2),gate:gate,doneAction:2);

			mix = Pan2.ar(osc,pan) * env ;

			Out.ar(150, mix )
		}
	).add;

	SynthDef(\masterSynth,{

		arg amp;
		var in,mix;

		in = In.ar(150,2);

		mix = Limiter.ar(in,0.9,0.01);

		mix = GVerb.ar(mix*0.4,10,4,0.2)+mix;

		Out.ar(0,mix);
	}
	).add;

	//sync
	s.sync;

	//call synths

	Synth(\masterSynth);

	MIDIdef.noteOn(\tunings,{

		arg a,b,c;

		var note;

		note = b.keyToDegree(~asScale,~scaleSize).degreeToKey(~asScale).midicps;

		~noteArray.put(b,Synth(\sineScale,
			[
				\freq,(note * 6).postcs , ///achtung * 6 bei 31
				\gate,1,
				\amp,a/127 * 0.5,
				\att,0.03,
				\dec,0.1,
				\sus,0.4,
				\rel,1.5
			]
		)
		);

	},nil,0
	);

	MIDIdef.noteOff(\tuningsOff,{

		arg a,b,c;

		~noteArray.at(b).set(\gate,0);

	},nil,0);
}
)

