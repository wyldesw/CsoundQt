<CsoundSynthesizer>
<CsOptions>
-odac -+max_str_len=10000 -b 2048 -B 8192
</CsOptions>
<CsInstruments>

/****MIXDOWN PLAYER ****/
;joachim heintz june 2010
;Mixes N mono soundfiles 
;to M channels, with panning.
;If N=M, it's a 1:1 player.

sr = 44100
ksmps = 512
nchnls = 2; change here if your device has more channels
0dbfs = 1


  opcode StrayGetEl, ii, Sijj
;returns the startindex and the endindex (= the first space after the element) for ielindex in String. if startindex returns -1, the element has not been found
Stray, ielindx, isepA, isepB xin
;;DEFINE THE SEPERATORS
isep1		=		(isepA == -1 ? 32 : isepA)
isep2		=		(isepA == -1 && isepB == -1 ? 9 : (isepB == -1 ? isep1 : isepB))
Sep1		sprintf	"%c", isep1
Sep2		sprintf	"%c", isep2
;;INITIALIZE SOME PARAMETERS
ilen		strlen		Stray
istartsel	=		-1; startindex for searched element
iendsel	=		-1; endindex for searched element
iel		=		0; actual number of element while searching
iwarleer	=		1
indx		=		0
 if ilen == 0 igoto end ;don't go into the loop if Stray is empty
loop:
Snext		strsub		Stray, indx, indx+1; next sign
isep1p		strcmp		Snext, Sep1; returns 0 if Snext is sep1
isep2p		strcmp		Snext, Sep2; 0 if Snext is sep2
;;NEXT SIGN IS NOT SEP1 NOR SEP2
if isep1p != 0 && isep2p != 0 then
 if iwarleer == 1 then; first character after a seperator 
  if iel == ielindx then; if searched element index
istartsel	=		indx; set it
iwarleer	=		0
  else 			;if not searched element index
iel		=		iel+1; increase it
iwarleer	=		0; log that it's not a seperator 
  endif 
 endif 
;;NEXT SIGN IS SEP1 OR SEP2
else 
 if istartsel > -1 then; if this is first selector after searched element
iendsel	=		indx; set iendsel
		igoto		end ;break
 else	
iwarleer	=		1
 endif 
endif
		loop_lt	indx, 1, ilen, loop 
end: 		xout		istartsel, iendsel
  endop 

  opcode StrayLen, i, Sjj
;returns the number of elements in Stray. elements are defined by two seperators as ASCII coded characters: isep1 defaults to 32 (= space), isep2 defaults to 9 (= tab). if just one seperator is used, isep2 equals isep1
Stray, isepA, isepB xin
;;DEFINE THE SEPERATORS
isep1		=		(isepA == -1 ? 32 : isepA)
isep2		=		(isepA == -1 && isepB == -1 ? 9 : (isepB == -1 ? isep1 : isepB))
Sep1		sprintf	"%c", isep1
Sep2		sprintf	"%c", isep2
;;INITIALIZE SOME PARAMETERS
ilen		strlen		Stray
icount		=		0; number of elements
iwarsep	=		1
indx		=		0
 if ilen == 0 igoto end ;don't go into the loop if String is empty
loop:
Snext		strsub		Stray, indx, indx+1; next sign
isep1p		strcmp		Snext, Sep1; returns 0 if Snext is sep1
isep2p		strcmp		Snext, Sep2; 0 if Snext is sep2
 if isep1p == 0 || isep2p == 0 then; if sep1 or sep2
iwarsep	=		1; tell the log so
 else 				; if not 
  if iwarsep == 1 then	; and has been sep1 or sep2 before
icount		=		icount + 1; increase counter
iwarsep	=		0; and tell you are ot sep1 nor sep2 
  endif 
 endif	
		loop_lt	indx, 1, ilen, loop 
end: 		xout		icount
  endop 
  
  opcode FildurMax, i, Sj
;returns the duration of the longest file in a list of filenames
Stray, isep	xin; list of filenames and seperator as ascii code (default=124)
isep		=		(isep == -1 ? 124 : isep)
infiles	StrayLen	Stray, isep
indx		=		0
imaxdur	=		0
loop:
ist, ien	StrayGetEl	Stray, indx, isep
Sel		strsub		Stray, ist, ien
idur		filelen	Sel
imaxdur	=		(idur > imaxdur ? idur : imaxdur)
		loop_lt	indx, 1, infiles, loop
		xout		imaxdur
  endop
  
  opcode Checksr, 0, Sj
Stray, isep	xin; list of filenames and seperator as ascii code (default=124)
isep		=		(isep == -1 ? 124 : isep)
infiles	StrayLen	Stray, isep
indx		=		0
loop:
ist, ien	StrayGetEl	Stray, indx, isep
Sel		strsub		Stray, ist, ien
ifilsr		filesr		Sel
 if ifilsr != sr then
printf_i "WARNING: Samplerate of file %s does not match the orchestra's sr (%d vs %d). Samplerate will be converted by diskin2.\n", 1, Sel, ifilsr, sr
 endif
		loop_lt	indx, 1, infiles, loop
  endop

  opcode MxdwnPlay, 0, Siiiiki
Stray, ilen, ichnls, ifirstchn iel, kvol, iskip xin
ipan 		=		iel * ((ichnls-1)/(ilen-1))
ioutch1	=		int(ipan)+ifirstchn
ioutch2	=		ioutch1+1
Soutch1	sprintf	"outchn%d", ioutch1
Soutch2	sprintf	"outchn%d", ioutch2
ipan2		=		frac(ipan)
ist, ien	StrayGetEl	Stray, iel, 124
Sel		strsub		Stray, ist, ien
asig		diskin2	Sel, 1, iskip
iscale		=		ichnls / ilen
a1, a2		pan2		asig*iscale*kvol, ipan2
		chnmix 	a1, Soutch1
if ipan != 0 then
		chnmix 	a2, Soutch2
endif
if iel < ilen-1 then
		MxdwnPlay 	Stray, ilen, ichnls, ifirstchn, iel+1, kvol, iskip
endif
  endop

  opcode ShowLED_a, 0, Sakkk
;Shows an audio signal in an outvalue channel. You can choose to show the value in dB or in raw amplitudes.
;;Input:
;Soutchan: string with the name of the outvalue channel
;asig: audio signal which is to displayed
;kdispfreq: refresh frequency (Hz)
;kdb: 1 = show in dB, 0 = show in raw amplitudes (both in the range 0-1)
;kdbrange: if idb=1: how many db-steps are shown (e.g. if 36 you will not see anything from a signal below -36 dB)
Soutchan, asig, kdispfreq, kdb, kdbrange	xin
kdispval	max_k	asig, kdispfreq, 1
	if kdb != 0 then
kdb 		= 		dbfsamp(kdispval)
kval 		= 		(kdbrange + kdb) / kdbrange
	else
kval		=		kdispval
	endif
			outvalue	Soutchan, kval
  endop


  opcode ShowOver_a, 0, Sakk
;Shows if the incoming audio signal was more than 1 and stays there for some time
;;Input:
;Soutchan: string with the name of the outvalue channel
;asig: audio signal which is to displayed
;kdispfreq: refresh frequency (Hz)
;khold: time in seconds to "hold the red light"
Soutchan, asig, kdispfreq, khold	xin
kon		init		0
ktim		times
kstart		init		0
kend		init		0
khold		=		(khold < .01 ? .01 : khold); avoiding too short hold times
kmax		max_k		asig, kdispfreq, 1
	if kon == 0 && kmax > 1 then
kstart		=		ktim
kend		=		kstart + khold
		outvalue	Soutchan, kmax
kon		=		1
	endif
	if kon == 1 && ktim > kend then
		outvalue	Soutchan, 0
kon		=		0
	endif
  endop

  opcode CollectShowClear, 0, iiikiii
;collect the audio channels, sends them to the display, and clears the global audio channel
ichnls, ifirstout, icount, ktrigdisp, idboramp, idbrange, icliphold xin
Soutchn	sprintf	"outchn%d", icount+ifirstout
Sdisp		sprintf	"out%d", icount+1
Sover		sprintf	"over%d", icount+1
Schn		sprintf	"chn%d", icount+1
Schnval	sprintf	"%d", ifirstout+icount
acollect	chnget		Soutchn
		outch		ifirstout+icount, acollect
		ShowLED_a	Sdisp, acollect, ktrigdisp, idboramp, idbrange
		ShowOver_a	Sover, acollect, ktrigdisp, icliphold
		outvalue	Schn, Schnval
		chnclear	Soutchn
 if icount+1 < ichnls then
 		CollectShowClear ichnls, ifirstout, icount+1, ktrigdisp, idboramp, idbrange, icliphold
 endif
  endop

instr 1
;input values
Stray 		invalue	"_MBrowse"
		Checksr	Stray
idur		FildurMax	Stray
ilen		StrayLen	Stray, 124
kchnls		invalue	"numoutch"
kfirstout	invalue	"firstout"
kskip		invalue	"skip"
kdb		invalue	"db"
kvol		=		ampdb(kdb)
ichnls		=		i(kchnls)
ifirstout	=		i(kfirstout)
iskip 		=		i(kskip)
p3		=		idur - iskip

;play as many channels as there are monofiles given, and pan to the output channels
		MxdwnPlay	Stray, ilen, ichnls, ifirstout, 0, kvol, iskip

;;display time
ktim		timeinsts
kplaypos	=		iskip + ktim
kposmin	=		floor(kplaypos/60)
kpossec	=		floor(kplaypos%60)
Smin		sprintfk	"%02d", kposmin
Ssec		sprintfk	"%02d", kpossec
		outvalue	"min", Smin
		outvalue	"sec", Ssec
		
;;collect and display mixdown audio signals
idboramp	=		1; 0=raw amps, 1=db
idbrange	=		48
icliphold	=		2
ktrigdisp	metro		10
		CollectShowClear ichnls, ifirstout, 0, ktrigdisp, idboramp, idbrange, icliphold
endin

</CsInstruments>
<CsScore>
i 1 0 1
e
</CsScore>
</CsoundSynthesizer><bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>351</x>
 <y>137</y>
 <width>463</width>
 <height>581</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="background">
  <r>186</r>
  <g>168</g>
  <b>91</b>
 </bgcolor>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>30</x>
  <y>56</y>
  <width>399</width>
  <height>124</height>
  <uuid>{e7d12ace-4150-46b5-929b-12b1cb9665aa}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>324</x>
  <y>316</y>
  <width>96</width>
  <height>76</height>
  <uuid>{1bfffffe-61dc-4355-8d70-96591bf074a2}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>border</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>375</x>
  <y>362</y>
  <width>37</width>
  <height>28</height>
  <uuid>{d7ca2aae-1384-4486-9c52-8c527b828211}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>sec</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>333</x>
  <y>362</y>
  <width>37</width>
  <height>28</height>
  <uuid>{52f700e3-1b22-4bc9-b53f-f1125ea6f976}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>min</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>364</x>
  <y>339</y>
  <width>17</width>
  <height>27</height>
  <uuid>{a9d9274f-379f-4db8-86a2-1d04781b8628}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>:</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>sec</objectName>
  <x>379</x>
  <y>339</y>
  <width>33</width>
  <height>26</height>
  <uuid>{a3a1342d-dd5b-419c-8b75-982f9d4c9592}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>00</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>min</objectName>
  <x>333</x>
  <y>339</y>
  <width>33</width>
  <height>26</height>
  <uuid>{0e9ebddd-002b-4d81-9f3e-31d8174a9824}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>00</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>324</x>
  <y>316</y>
  <width>94</width>
  <height>26</height>
  <uuid>{a82a80c2-a91d-4602-b7b9-f7a43bf27c9f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Time</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>numoutch</objectName>
  <x>230</x>
  <y>319</y>
  <width>43</width>
  <height>28</height>
  <uuid>{fa061585-35fe-4b3e-8430-ab36d8832901}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>0</minimum>
  <maximum>1e+12</maximum>
  <randomizable group="0">false</randomizable>
  <value>2</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>29</x>
  <y>319</y>
  <width>203</width>
  <height>27</height>
  <uuid>{26b0c8cc-b398-4ff3-9808-b0d8ba7287ba}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Number Of Output Channels</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>firstout</objectName>
  <x>184</x>
  <y>350</y>
  <width>44</width>
  <height>27</height>
  <uuid>{b2a47df0-7f7f-4758-b32d-6e630f52968d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>1.00000000</resolution>
  <minimum>0</minimum>
  <maximum>1e+12</maximum>
  <randomizable group="0">false</randomizable>
  <value>1</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>29</x>
  <y>350</y>
  <width>156</width>
  <height>27</height>
  <uuid>{6b0b43c9-be40-4456-9e0f-292305d8c4e0}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>First Output Channel</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>352</x>
  <y>118</y>
  <width>33</width>
  <height>29</height>
  <uuid>{e5582d70-8ce5-4c13-b3cf-1881b90a64ac}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>8</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>316</x>
  <y>119</y>
  <width>33</width>
  <height>29</height>
  <uuid>{b53ba656-e24c-4e19-b691-046114065a73}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>7</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>278</x>
  <y>119</y>
  <width>33</width>
  <height>29</height>
  <uuid>{94b9f142-532b-4c7d-ab6b-59b855371762}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>6</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>241</x>
  <y>119</y>
  <width>33</width>
  <height>29</height>
  <uuid>{56576ebf-1348-4ed8-bbf8-98040716404f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>5</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>205</x>
  <y>119</y>
  <width>33</width>
  <height>29</height>
  <uuid>{b1dda0f4-3208-42cf-8dce-9fa4c5b84291}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>4</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>168</x>
  <y>119</y>
  <width>33</width>
  <height>29</height>
  <uuid>{cc6164c0-5283-4586-b272-0965f8af304c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>3</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>131</x>
  <y>119</y>
  <width>33</width>
  <height>29</height>
  <uuid>{c12d11bc-4e9f-4cca-a214-87fe8decef1f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>2</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>94</x>
  <y>119</y>
  <width>33</width>
  <height>29</height>
  <uuid>{f07326a2-2d40-4520-a3c4-cb13f0e6a4aa}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>1</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>352</x>
  <y>148</y>
  <width>33</width>
  <height>29</height>
  <uuid>{04836764-ae09-40d9-a9e1-3f83dce56fa5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>R</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>94</x>
  <y>147</y>
  <width>33</width>
  <height>29</height>
  <uuid>{82a72ce3-b186-482b-976d-944b8f7d785c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>L</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>29</x>
  <y>146</y>
  <width>52</width>
  <height>29</height>
  <uuid>{c24d1300-e14b-40de-b04a-b811acd9fefe}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>OUT</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>29</x>
  <y>118</y>
  <width>52</width>
  <height>29</height>
  <uuid>{7cc2eebb-6511-40e4-9da1-af23fe354c21}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>IN</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>30</x>
  <y>59</y>
  <width>397</width>
  <height>59</height>
  <uuid>{eac54750-f5e9-4b16-a34e-a692ad43125f}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Mixes any number of mono soundfiles to any number of output channels by panning. For instance, if you mix 8 channels down to 2, it will be done in this way:</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>73</x>
  <y>11</y>
  <width>308</width>
  <height>42</height>
  <uuid>{e23734f1-521f-4e65-9d55-58f2751ebc8b}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>MIXDOWN PLAYER</label>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>22</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>42</x>
  <y>277</y>
  <width>67</width>
  <height>27</height>
  <uuid>{06c607cd-5822-47bb-9ecf-977bebb09709}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Gain</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>370</x>
  <y>278</y>
  <width>47</width>
  <height>27</height>
  <uuid>{940a92e4-9d25-4003-9578-7ca125f0b716}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>dB</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>db</objectName>
  <x>320</x>
  <y>277</y>
  <width>52</width>
  <height>28</height>
  <uuid>{b91f69a5-a47c-4ea1-9d0f-046e44defbd8}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>0.000</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>-5</x>
  <y>231</y>
  <width>80</width>
  <height>25</height>
  <uuid>{6d596540-3556-428d-bf81-e3302d85780c}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Skiptime</label>
  <alignment>right</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBHSlider">
  <objectName>db</objectName>
  <x>109</x>
  <y>277</y>
  <width>212</width>
  <height>28</height>
  <uuid>{25d39018-0dcb-4f63-a4b6-519ef8219aa7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <minimum>-12.00000000</minimum>
  <maximum>12.00000000</maximum>
  <value>0.00000000</value>
  <mode>lin</mode>
  <mouseControl act="jump">continuous</mouseControl>
  <resolution>-1.00000000</resolution>
  <randomizable group="0">false</randomizable>
 </bsbObject>
 <bsbObject version="2" type="BSBSpinBox">
  <objectName>skip</objectName>
  <x>78</x>
  <y>230</y>
  <width>65</width>
  <height>27</height>
  <uuid>{1eeb0757-ffae-471e-a3fa-4210eaa86a53}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <resolution>0.00100000</resolution>
  <minimum>0</minimum>
  <maximum>1e+12</maximum>
  <randomizable group="0">false</randomizable>
  <value>0</value>
 </bsbObject>
 <bsbObject version="2" type="BSBLineEdit">
  <objectName>_MBrowse</objectName>
  <x>19</x>
  <y>189</y>
  <width>305</width>
  <height>27</height>
  <uuid>{ea4bc9f6-b558-4a2a-9410-25edec264224}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>left</alignment>
  <font>Lucida Grande</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <background>nobackground</background>
 </bsbObject>
 <bsbObject version="2" type="BSBButton">
  <objectName>_MBrowse</objectName>
  <x>327</x>
  <y>189</y>
  <width>100</width>
  <height>30</height>
  <uuid>{368327a9-899a-403b-a55b-95357c3dbafe}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <type>value</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Select Files</text>
  <image>/</image>
  <eventLine/>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>out1</objectName>
  <x>32</x>
  <y>419</y>
  <width>25</width>
  <height>100</height>
  <uuid>{496461c8-c3d7-47f7-8492-0468174480e7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>out1</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>-inf</xValue>
  <yValue>-inf</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>over2</objectName>
  <x>32</x>
  <y>395</y>
  <width>25</width>
  <height>25</height>
  <uuid>{37e14c1d-f864-4d2d-a955-3ef825e77185}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>over2</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>155</r>
   <g>3</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>out2</objectName>
  <x>64</x>
  <y>419</y>
  <width>25</width>
  <height>100</height>
  <uuid>{b8737139-8ae2-4743-98db-a80e11912ca3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>out2</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>-inf</xValue>
  <yValue>-inf</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>over1</objectName>
  <x>64</x>
  <y>395</y>
  <width>25</width>
  <height>25</height>
  <uuid>{a8e39457-553c-41c5-bf44-ccf3379bc584}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>over1</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>155</r>
   <g>3</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>out3</objectName>
  <x>97</x>
  <y>419</y>
  <width>25</width>
  <height>100</height>
  <uuid>{605082ea-44b3-4aed-9dad-b54709f3b8f9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>out3</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>-inf</xValue>
  <yValue>-inf</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>over3</objectName>
  <x>97</x>
  <y>395</y>
  <width>25</width>
  <height>25</height>
  <uuid>{48db23f6-2e0d-4d1e-974e-c9487c4c3138}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>over3</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>155</r>
   <g>3</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>out4</objectName>
  <x>129</x>
  <y>419</y>
  <width>25</width>
  <height>100</height>
  <uuid>{9e16567b-0059-4f86-9b4d-300aa5bf2afe}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>out4</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>-inf</xValue>
  <yValue>-inf</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>over4</objectName>
  <x>129</x>
  <y>395</y>
  <width>25</width>
  <height>25</height>
  <uuid>{26355726-dad2-44a1-8043-e4620741fd15}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>over4</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>155</r>
   <g>3</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>out5</objectName>
  <x>163</x>
  <y>419</y>
  <width>25</width>
  <height>100</height>
  <uuid>{81470802-54bd-4a6c-be49-daa9a478552d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>out5</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>-inf</xValue>
  <yValue>-inf</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>over5</objectName>
  <x>163</x>
  <y>395</y>
  <width>25</width>
  <height>25</height>
  <uuid>{8db2e10f-1624-4d72-b4fe-1778191df70e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>over5</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>155</r>
   <g>3</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>out6</objectName>
  <x>195</x>
  <y>419</y>
  <width>25</width>
  <height>100</height>
  <uuid>{e83b3c5d-c1bc-4d3f-85c5-856165c8bb9d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>out6</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>-inf</xValue>
  <yValue>-inf</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>over6</objectName>
  <x>195</x>
  <y>395</y>
  <width>25</width>
  <height>25</height>
  <uuid>{8714d646-5805-4fc5-848c-00eb7e3dc30e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>over6</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>155</r>
   <g>3</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>out7</objectName>
  <x>228</x>
  <y>419</y>
  <width>25</width>
  <height>100</height>
  <uuid>{dc9eba00-b83d-4179-802b-b91532fd134a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>out7</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>-inf</xValue>
  <yValue>-inf</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>over7</objectName>
  <x>228</x>
  <y>395</y>
  <width>25</width>
  <height>25</height>
  <uuid>{6d0b2991-eed8-4871-947f-67bc67313855}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>over7</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>155</r>
   <g>3</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>out8</objectName>
  <x>260</x>
  <y>419</y>
  <width>25</width>
  <height>100</height>
  <uuid>{99e658f1-d30b-415a-8a60-528f39dfd1e6}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>out8</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>-inf</xValue>
  <yValue>-inf</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>0</r>
   <g>234</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBController">
  <objectName>over8</objectName>
  <x>260</x>
  <y>395</y>
  <width>25</width>
  <height>25</height>
  <uuid>{85b38a7f-e962-4601-bced-83da2ddb45fd}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <objectName2>over8</objectName2>
  <xMin>0.00000000</xMin>
  <xMax>1.00000000</xMax>
  <yMin>0.00000000</yMin>
  <yMax>1.00000000</yMax>
  <xValue>0.00000000</xValue>
  <yValue>0.00000000</yValue>
  <type>fill</type>
  <pointsize>1</pointsize>
  <fadeSpeed>0.00000000</fadeSpeed>
  <mouseControl act="press">jump</mouseControl>
  <color>
   <r>155</r>
   <g>3</g>
   <b>0</b>
  </color>
  <randomizable mode="both" group="0">false</randomizable>
  <bgcolor>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </bgcolor>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>chn1</objectName>
  <x>32</x>
  <y>527</y>
  <width>26</width>
  <height>28</height>
  <uuid>{93704853-a825-47eb-8ebe-f98787fc5f93}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>chn2</objectName>
  <x>65</x>
  <y>527</y>
  <width>26</width>
  <height>28</height>
  <uuid>{7eac2f72-d419-4170-aae4-ae86c93a883d}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>chn3</objectName>
  <x>96</x>
  <y>527</y>
  <width>26</width>
  <height>28</height>
  <uuid>{e65ccd55-3ea5-4533-98a9-2cbb7522c808}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>chn4</objectName>
  <x>129</x>
  <y>527</y>
  <width>26</width>
  <height>28</height>
  <uuid>{b623e5e3-f099-48fa-bf4d-47d1ce8740aa}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>chn5</objectName>
  <x>162</x>
  <y>527</y>
  <width>26</width>
  <height>28</height>
  <uuid>{56cd1e29-4de0-4afd-b397-dfdfd0706ad5}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>chn6</objectName>
  <x>195</x>
  <y>527</y>
  <width>26</width>
  <height>28</height>
  <uuid>{342db427-ee50-4a2d-89a2-1e4019a29082}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>chn7</objectName>
  <x>226</x>
  <y>527</y>
  <width>26</width>
  <height>28</height>
  <uuid>{de3febd8-3541-47b8-b52a-64f587255123}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBDisplay">
  <objectName>chn8</objectName>
  <x>259</x>
  <y>527</y>
  <width>26</width>
  <height>28</height>
  <uuid>{754a616e-23e5-4592-ac5e-14644c8261af}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label/>
  <alignment>center</alignment>
  <font>Arial</font>
  <fontsize>14</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>324</x>
  <y>531</y>
  <width>80</width>
  <height>25</height>
  <uuid>{197181c4-cd2d-4977-bf2e-f6570b96c4a3}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Output Channel</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>12</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBLabel">
  <objectName/>
  <x>319</x>
  <y>396</y>
  <width>116</width>
  <height>123</height>
  <uuid>{5fc86a90-3ef0-4d41-a138-8342b66ec8b9}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <label>Make sure your nchnls value in the orchestra header matches the desired number of channels!</label>
  <alignment>left</alignment>
  <font>Arial</font>
  <fontsize>10</fontsize>
  <precision>3</precision>
  <color>
   <r>0</r>
   <g>0</g>
   <b>0</b>
  </color>
  <bgcolor mode="nobackground">
   <r>255</r>
   <g>255</g>
   <b>255</b>
  </bgcolor>
  <bordermode>noborder</bordermode>
  <borderradius>1</borderradius>
  <borderwidth>1</borderwidth>
 </bsbObject>
 <bsbObject version="2" type="BSBButton">
  <objectName>_Start</objectName>
  <x>148</x>
  <y>230</y>
  <width>73</width>
  <height>28</height>
  <uuid>{6cbdcf1e-784e-4e9b-9b92-9f6b8465a20a}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <type>value</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Start</text>
  <image>/</image>
  <eventLine/>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject version="2" type="BSBButton">
  <objectName>_Stop</objectName>
  <x>222</x>
  <y>230</y>
  <width>73</width>
  <height>28</height>
  <uuid>{7a569dc3-eb33-443e-97a1-9f545ba5f4f7}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <type>value</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Stop</text>
  <image>/</image>
  <eventLine/>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject version="2" type="BSBButton">
  <objectName>_Pause</objectName>
  <x>295</x>
  <y>230</y>
  <width>73</width>
  <height>28</height>
  <uuid>{a8df2037-d751-47eb-aa7c-bb5b69c9c94e}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <type>value</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Pause</text>
  <image>/</image>
  <eventLine/>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <bsbObject version="2" type="BSBButton">
  <objectName>_Play</objectName>
  <x>368</x>
  <y>230</y>
  <width>73</width>
  <height>28</height>
  <uuid>{0c7f121e-3908-4a27-8a4e-81bbbf5b0d22}</uuid>
  <visible>true</visible>
  <midichan>0</midichan>
  <midicc>-3</midicc>
  <type>value</type>
  <pressedValue>1.00000000</pressedValue>
  <stringvalue/>
  <text>Resume</text>
  <image>/</image>
  <eventLine/>
  <latch>false</latch>
  <latched>false</latched>
 </bsbObject>
 <objectName/>
 <x>351</x>
 <y>137</y>
 <width>463</width>
 <height>581</height>
 <visible>true</visible>
</bsbPanel>
<bsbPresets>
</bsbPresets>
<MacGUI>
ioView background {47802, 43176, 23387}
ioText {30, 56} {399, 124} label 0.000000 0.00100 "" center "Arial" 10 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {324, 316} {96, 76} label 0.000000 0.00100 "" left "Arial" 10 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {375, 362} {37, 28} label 0.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder sec
ioText {333, 362} {37, 28} label 0.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder min
ioText {364, 339} {17, 27} label 0.000000 0.00100 "" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder :
ioText {379, 339} {33, 26} display 0.000000 0.00100 "sec" left "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 00
ioText {333, 339} {33, 26} display 0.000000 0.00100 "min" right "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 00
ioText {324, 316} {94, 26} label 0.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder Time
ioText {230, 319} {43, 28} editnum 2.000000 1.000000 "numoutch" left "" 0 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 2.000000
ioText {29, 319} {203, 27} label 0.000000 0.00100 "" left "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder Number Of Output Channels
ioText {184, 350} {44, 27} editnum 1.000000 1.000000 "firstout" left "" 0 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 1.000000
ioText {29, 350} {156, 27} label 0.000000 0.00100 "" left "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder First Output Channel
ioText {352, 118} {33, 29} label 8.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 8
ioText {316, 119} {33, 29} label 7.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 7
ioText {278, 119} {33, 29} label 6.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 6
ioText {241, 119} {33, 29} label 5.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 5
ioText {205, 119} {33, 29} label 4.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 4
ioText {168, 119} {33, 29} label 3.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 3
ioText {131, 119} {33, 29} label 2.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 2
ioText {94, 119} {33, 29} label 1.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 1
ioText {352, 148} {33, 29} label 0.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder R
ioText {94, 147} {33, 29} label 0.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder L
ioText {29, 146} {52, 29} label 0.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder OUT
ioText {29, 118} {52, 29} label 0.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder IN
ioText {30, 59} {397, 59} label 0.000000 0.00100 "" center "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder Mixes any number of mono soundfiles to any number of output channels by panning. For instance, if you mix 8 channels down to 2, it will be done in this way:
ioText {73, 11} {308, 42} label 0.000000 0.00100 "" center "Arial" 22 {0, 0, 0} {65280, 65280, 65280} nobackground noborder MIXDOWN PLAYER
ioText {42, 277} {67, 27} label 0.000000 0.00100 "" right "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder Gain
ioText {370, 278} {47, 27} label 0.000000 0.00100 "" left "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder dB
ioText {320, 277} {52, 28} display 0.000000 0.00100 "db" left "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 0.000
ioText {253, 188} {80, 25} label 0.000000 0.00100 "" right "Arial" 10 {0, 0, 0} {65280, 65280, 65280} nobackground noborder Skiptime
ioSlider {109, 277} {212, 28} -12.000000 12.000000 0.000000 db
ioText {336, 187} {65, 27} editnum 0.000000 0.001000 "skip" left "" 0 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 0.000000
ioText {19, 189} {305, 27} edit 0.000000 0.00100 "_MBrowse"  "Lucida Grande" 12 {0, 0, 0} {65280, 65280, 65280} falsenoborder 
ioButton {327, 189} {100, 30} value 1.000000 "_MBrowse" "Select Files" "/" 
ioMeter {32, 419} {25, 100} {0, 59904, 0} "out1" -inf "out1" -inf fill 1 0 mouse
ioMeter {32, 395} {25, 25} {39680, 768, 0} "over2" 0.000000 "over2" 0.000000 fill 1 0 mouse
ioMeter {64, 419} {25, 100} {0, 59904, 0} "out2" -inf "out2" -inf fill 1 0 mouse
ioMeter {64, 395} {25, 25} {39680, 768, 0} "over1" 0.000000 "over1" 0.000000 fill 1 0 mouse
ioMeter {97, 419} {25, 100} {0, 59904, 0} "out3" -inf "out3" -inf fill 1 0 mouse
ioMeter {97, 395} {25, 25} {39680, 768, 0} "over3" 0.000000 "over3" 0.000000 fill 1 0 mouse
ioMeter {129, 419} {25, 100} {0, 59904, 0} "out4" -inf "out4" -inf fill 1 0 mouse
ioMeter {129, 395} {25, 25} {39680, 768, 0} "over4" 0.000000 "over4" 0.000000 fill 1 0 mouse
ioMeter {163, 419} {25, 100} {0, 59904, 0} "out5" -inf "out5" -inf fill 1 0 mouse
ioMeter {163, 395} {25, 25} {39680, 768, 0} "over5" 0.000000 "over5" 0.000000 fill 1 0 mouse
ioMeter {195, 419} {25, 100} {0, 59904, 0} "out6" -inf "out6" -inf fill 1 0 mouse
ioMeter {195, 395} {25, 25} {39680, 768, 0} "over6" 0.000000 "over6" 0.000000 fill 1 0 mouse
ioMeter {228, 419} {25, 100} {0, 59904, 0} "out7" -inf "out7" -inf fill 1 0 mouse
ioMeter {228, 395} {25, 25} {39680, 768, 0} "over7" 0.000000 "over7" 0.000000 fill 1 0 mouse
ioMeter {260, 419} {25, 100} {0, 59904, 0} "out8" -inf "out8" -inf fill 1 0 mouse
ioMeter {260, 395} {25, 25} {39680, 768, 0} "over8" 0.000000 "over8" 0.000000 fill 1 0 mouse
ioText {32, 527} {26, 28} display 0.000000 0.00100 "chn1" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {65, 527} {26, 28} display 0.000000 0.00100 "chn2" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {96, 527} {26, 28} display 0.000000 0.00100 "chn3" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {129, 527} {26, 28} display 0.000000 0.00100 "chn4" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {162, 527} {26, 28} display 0.000000 0.00100 "chn5" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {195, 527} {26, 28} display 0.000000 0.00100 "chn6" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {226, 527} {26, 28} display 0.000000 0.00100 "chn7" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {259, 527} {26, 28} display 0.000000 0.00100 "chn8" center "Arial" 14 {0, 0, 0} {65280, 65280, 65280} nobackground noborder 
ioText {324, 531} {80, 25} label 0.000000 0.00100 "" left "Arial" 12 {0, 0, 0} {65280, 65280, 65280} nobackground noborder Output Channel
ioText {319, 396} {116, 123} label 0.000000 0.00100 "" left "Arial" 10 {0, 0, 0} {65280, 65280, 65280} nobackground noborder Make sure your nchnls value in the orchestra header matches the desired number of channels!
ioButton {148, 230} {73, 28} value 1.000000 "_Start" "Start" "/" 
ioButton {222, 230} {73, 28} value 1.000000 "_Stop" "Stop" "/" 
ioButton {295, 230} {73, 28} value 1.000000 "_Pause" "Pause" "/" 
ioButton {368, 230} {73, 28} value 1.000000 "_Play" "Resume" "/" 
</MacGUI>
