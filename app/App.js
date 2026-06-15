import React, { useState, useRef, useEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, ScrollView,
  StyleSheet, Platform, SafeAreaView, StatusBar,
  ActivityIndicator, Alert, Keyboard,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

/* ═══ APIs ═══ */
const DB   = 'https://v6.db.transport.rest';
const GEO  = 'https://api.transitous.org/api/v1/geocode';
const PLAN = 'https://api.transitous.org/api/v3/plan';
const DEPS = 'https://api.transitous.org/api/v1/stoptimes';

/* ═══ Colors ═══ */
const C = {
  bg: '#F2F2F7', card: '#FFFFFF',
  label: '#000', label2: 'rgba(60,60,67,.6)', label3: 'rgba(60,60,67,.3)',
  sep: 'rgba(60,60,67,.12)', fill: 'rgba(120,120,128,.12)',
  blue: '#007AFF', red: '#FF3B30', green: '#34C759',
  orange: '#FF9500', brand: '#EC0016',
  brandSoft: 'rgba(236,0,22,.1)', greenSoft: 'rgba(52,199,89,.12)',
  orangeSoft: 'rgba(255,149,0,.12)', blueSoft: 'rgba(0,122,255,.1)',
};

/* ═══ Helpers ═══ */
const fmt  = iso => iso ? new Date(iso).toLocaleTimeString('de-DE',{hour:'2-digit',minute:'2-digit'}) : '--:--';
const dur  = s => { if(!s||s<0)return'?'; const h=Math.floor(s/3600),m=Math.floor((s%3600)/60); return h>0?`${h}h ${m}min`:`${m} min`; };
const dly  = (a,b) => (a&&b) ? Math.round((new Date(b)-new Date(a))/60000) : 0;

const lineCol = n => {
  if(!n) return '#8E8E93';
  const u=n.toUpperCase();
  if(/ICE/.test(u)) return '#EC0016';
  if(/^IC|^EC/.test(u)) return '#C4000F';
  if(/^RE|^RB/.test(u)) return '#0066CC';
  if(/^S\d/.test(u)) return '#007E3C';
  if(/^U\d/.test(u)) return '#1C4B9B';
  if(/STR|^T\d|^M\d/.test(u)) return '#C0003C';
  if(/BUS|NB/.test(u)) return '#7C3AED';
  return '#555';
};
const modeCol = m => {
  switch((m||'').toUpperCase()) {
    case 'HIGHSPEED_RAIL': return '#EC0016';
    case 'LONG_DISTANCE':  return '#C4000F';
    case 'REGIONAL_FAST_RAIL': case 'REGIONAL_RAIL': case 'RAIL': return '#0066CC';
    case 'SUBURBAN': case 'METRO': case 'SUBWAY': return '#007E3C';
    case 'TRAM': return '#C0003C';
    case 'BUS': case 'COACH': return '#7C3AED';
    default: return '#8E8E93';
  }
};
const stIcon = (p,m) => {
  if(p){ if(p.nationalExpress||p.national)return'🚄'; if(p.regionalExpress||p.regional)return'🚆'; if(p.suburban)return'🚊'; if(p.subway)return'🚇'; if(p.tram)return'🚋'; if(p.bus)return'🚌'; }
  if(m){ if(m.includes('HIGHSPEED_RAIL')||m.includes('LONG_DISTANCE'))return'🚄'; if(m.includes('REGIONAL_RAIL'))return'🚆'; if(m.includes('SUBURBAN'))return'🚊'; if(m.includes('SUBWAY')||m.includes('METRO'))return'🚇'; if(m.includes('TRAM'))return'🚋'; if(m.includes('BUS'))return'🚌'; }
  return '🚉';
};

const SKIP = ['HIGHSPEED_RAIL','LONG_DISTANCE','NIGHT_RAIL','COACH'];
const RAIL = ['HIGHSPEED_RAIL','LONG_DISTANCE','REGIONAL_RAIL','SUBURBAN','RAIL'];

const transitLegs = (j, db) => (j.legs||[]).filter(l => db ? !l.walking : l.mode!=='WALK');
const legDep  = (l, db) => db ? (l.departure||l.plannedDeparture)       : (l.from?.departure||l.startTime);
const legArr  = (l, db) => db ? (l.arrival||l.plannedArrival)           : (l.to?.arrival||l.endTime);
const legDepP = (l, db) => db ? l.plannedDeparture                      : (l.from?.scheduledDeparture||l.scheduledStartTime);
const legArrP = (l, db) => db ? l.plannedArrival                        : (l.to?.scheduledArrival||l.scheduledEndTime);

/* ═══ Micro components ═══ */
const Pill = ({label,color}) => <View style={[s.pill,{backgroundColor:color}]}><Text style={s.pillTxt}>{label}</Text></View>;
const Sep  = () => <View style={s.sepLine}/>;

function PlatBadge({plat}){
  if(!plat) return null;
  return <View style={s.platChip}><Text style={s.platChipTxt}>Gl. {plat}</Text></View>;
}

function DelayTag({planned,real}){
  const d = dly(planned,real);
  if(d===0) return null;
  return <Text style={[s.dlyTag,{color:d>0?C.red:C.green}]}>{d>0?`+${d}`:'✓'}</Text>;
}

function SectionHdr({title,right}){
  return (
    <View style={s.sHdr}>
      <Text style={s.sHdrTxt}>{title}</Text>
      {right?<Text style={s.sHdrRight}>{right}</Text>:null}
    </View>
  );
}

/* ═══ Station Input ═══ */
let dbOk = true;

function StationInput({placeholder, value, onChange, onSelect, dotColor}){
  const [sugs, setSugs] = useState([]);
  const [busy, setBusy] = useState(false);
  const tmr = useRef(null);

  const fetch_ = async q => {
    if(q.length<2){setSugs([]);return;}
    setBusy(true);
    try {
      if(dbOk){
        try{
          const r = await fetch(`${DB}/locations?query=${encodeURIComponent(q)}&results=10&stops=true&addresses=false&poi=false`,{signal:AbortSignal.timeout(5000)});
          if(r.ok){
            const d=await r.json();
            setSugs((d||[]).map(x=>({id:x.id,name:x.name,lat:x.location?.latitude,lon:x.location?.longitude,products:x.products,_db:true,icon:stIcon(x.products)})));
            setBusy(false);return;
          }
        }catch{dbOk=false;}
      }
      const r=await fetch(`${GEO}?text=${encodeURIComponent(q)}&language=de`);
      const d=await r.json();
      const st=(d||[]).filter(x=>x.type==='STOP');
      st.sort((a,b)=>{const aR=(a.modes||[]).some(m=>RAIL.includes(m));const bR=(b.modes||[]).some(m=>RAIL.includes(m));if(aR&&!bR)return -1;if(!aR&&bR)return 1;return(b.importance||0)-(a.importance||0);});
      setSugs(st.slice(0,10).map(x=>({id:x.id,name:x.name,lat:x.lat,lon:x.lon,modes:x.modes,_db:false,icon:stIcon(null,x.modes)})));
    }catch{setSugs([]);}
    setBusy(false);
  };

  return (
    <View>
      <View style={s.inputRow}>
        <View style={[s.inputDot,{backgroundColor:dotColor}]}/>
        <TextInput
          style={s.inputTxt} placeholder={placeholder} placeholderTextColor={C.label3}
          value={value} autoCorrect={false} autoCapitalize="words"
          onChangeText={t=>{onChange(t);clearTimeout(tmr.current);tmr.current=setTimeout(()=>fetch_(t.trim()),220);}}
        />
        {busy&&<ActivityIndicator size="small" color={C.brand} style={{marginRight:12}}/>}
      </View>
      {sugs.length>0&&(
        <View style={s.drop}>
          {sugs.map((x,i)=>(
            <TouchableOpacity key={x.id+i} style={[s.dropRow,i>0&&s.dropSep]}
              onPress={()=>{onChange(x.name);onSelect(x);setSugs([]);Keyboard.dismiss();}} activeOpacity={0.6}>
              <Text style={s.dropIco}>{x.icon}</Text>
              <Text style={s.dropName} numberOfLines={1}>{x.name}</Text>
            </TouchableOpacity>
          ))}
        </View>
      )}
    </View>
  );
}

/* ═══ Journey Timeline ═══ */
function Timeline({j, db}){
  const legs = j.legs||[];
  const tLegs = transitLegs(j,db);

  return (
    <View style={s.timeline}>
      {legs.map((leg,idx)=>{
        const isWalk = db ? leg.walking : leg.mode==='WALK';

        if(isWalk){
          const m = db
            ? Math.ceil((new Date(leg.arrival)-new Date(leg.departure))/60000)
            : Math.round((leg.duration||0)/60);
          return (
            <View key={idx} style={s.tlWalkRow}>
              <View style={s.tlLeft}><View style={s.tlWalkLine}/></View>
              <View style={s.tlWalkBadge}><Text style={s.tlWalkTxt}>🚶 {m||1} min Fußweg</Text></View>
            </View>
          );
        }

        const ti = tLegs.indexOf(leg);
        const isFirst = ti===0, isLast = ti===tLegs.length-1;
        const col    = db ? lineCol(leg.line?.name) : modeCol(leg.mode);
        const lname  = db ? (leg.line?.name||'?') : (leg.routeShortName||leg.displayName||'?');
        const dir    = db ? (leg.direction||leg.destination?.name) : (leg.headsign||leg.to?.name);
        const frm    = db ? leg.origin?.name : leg.from?.name;
        const to_    = db ? leg.destination?.name : leg.to?.name;
        const dTime  = legDep(leg,db), dPlan=legDepP(leg,db);
        const aTime  = legArr(leg,db), aPlan=legArrP(leg,db);
        const dPlat  = db ? (leg.departurePlatform||leg.plannedDeparturePlatform) : leg.from?.track;
        const aPlat  = db ? (leg.arrivalPlatform||leg.plannedArrivalPlatform)    : leg.to?.track;

        let xferMin = 0;
        if(!isLast){
          const next = tLegs[ti+1];
          const nd = legDep(next,db);
          if(nd&&aTime) xferMin = Math.round((new Date(nd)-new Date(aTime))/60000);
        }

        return (
          <View key={idx}>
            {/* Departure */}
            <View style={s.tlRow}>
              <View style={s.tlLeft}>
                <View style={[s.tlDot,{backgroundColor:isFirst?C.green:col}]}/>
                <View style={[s.tlLineV,{backgroundColor:col}]}/>
              </View>
              <View style={s.tlContent}>
                <View style={s.tlTR}>
                  <Text style={s.tlTime}>{fmt(dTime)}</Text>
                  <DelayTag planned={dPlan} real={dTime}/>
                  <PlatBadge plat={dPlat}/>
                </View>
                <Text style={s.tlStation}>{frm}</Text>
                <View style={s.tlPR}>
                  <Pill label={lname} color={col}/>
                  <Text style={s.tlDir} numberOfLines={1}>→ {dir}</Text>
                </View>
              </View>
            </View>

            {/* Arrival */}
            <View style={s.tlRow}>
              <View style={s.tlLeft}>
                <View style={[s.tlDot,{backgroundColor:isLast?C.brand:'#C7C7CC'}]}/>
                {xferMin>0&&<View style={[s.tlLineV,{backgroundColor:'#D1D1D6'}]}/>}
              </View>
              <View style={[s.tlContent,{paddingBottom:xferMin>0?4:18}]}>
                <View style={s.tlTR}>
                  <Text style={s.tlTime}>{fmt(aTime)}</Text>
                  <DelayTag planned={aPlan} real={aTime}/>
                  <PlatBadge plat={aPlat}/>
                </View>
                <Text style={s.tlStation}>{to_}</Text>
              </View>
            </View>

            {/* Transfer */}
            {xferMin>0&&(
              <View style={s.tlXferRow}>
                <View style={s.tlLeft}/>
                <View style={[s.xferChip,{backgroundColor:xferMin<5?C.brandSoft:xferMin<10?C.orangeSoft:C.fill}]}>
                  <Text style={[s.xferTxt,{color:xferMin<5?C.brand:xferMin<10?C.orange:C.label2}]}>
                    ⏱ {xferMin} min Umstieg{xferMin<5?' · Sehr knapp!':xferMin<10?' · Knapp':''}
                  </Text>
                </View>
              </View>
            )}
          </View>
        );
      })}
    </View>
  );
}

/* ═══ Journey Card ═══ */
function JCard({j, db, fromName, toName, onSave, saved}){
  const [open,setOpen]=useState(false);
  const tl = transitLegs(j,db);
  if(!tl.length) return null;
  if(!db && tl.some(l=>SKIP.includes(l.mode))) return null;

  const f=tl[0], la=tl[tl.length-1];
  const depT=legDep(f,db), depP=legDepP(f,db);
  const arrT=legArr(la,db), arrP=legArrP(la,db);
  const d = db ? (new Date(arrT)-new Date(depT))/1000 : j.duration;
  const chg = tl.length-1;
  const dDep=dly(depP,depT), dArr=dly(arrP,arrT);
  const dPlat = db?(f.departurePlatform||f.plannedDeparturePlatform):f.from?.track;

  return (
    <View style={s.jCard}>
      <TouchableOpacity onPress={()=>setOpen(o=>!o)} activeOpacity={0.9}>
        <View style={s.jTop}>
          {/* Dep */}
          <View style={s.jCol}>
            <Text style={s.jTimeLg}>{fmt(depT)}</Text>
            {dDep!==0&&<Text style={[s.jDly,{color:dDep>0?C.red:C.green}]}>{dDep>0?`+${dDep} min`:'✓'}</Text>}
            {dPlat&&<View style={[s.platChip,{marginTop:4,alignSelf:'flex-start'}]}><Text style={s.platChipTxt}>Gl. {dPlat}</Text></View>}
          </View>
          {/* Mid */}
          <View style={s.jMid}>
            <Text style={s.jDurTxt}>{dur(d)}</Text>
            <View style={s.jBar}>
              <View style={[s.jBarDot,{backgroundColor:C.green,left:-3}]}/>
              <View style={[s.jBarDot,{backgroundColor:C.brand,right:-3}]}/>
            </View>
            <Text style={s.jChgTxt}>{chg===0?'Direkt':`${chg}× Umst.`}</Text>
          </View>
          {/* Arr */}
          <View style={[s.jCol,{alignItems:'flex-end'}]}>
            <Text style={s.jTimeLg}>{fmt(arrT)}</Text>
            {dArr!==0&&<Text style={[s.jDly,{color:dArr>0?C.red:C.green}]}>{dArr>0?`+${dArr} min`:'✓'}</Text>}
          </View>
        </View>

        <View style={s.jNames}>
          <Text style={s.jNameTxt} numberOfLines={1}>{fromName}</Text>
          <Text style={s.jNameTxt} numberOfLines={1}>{toName}</Text>
        </View>

        <View style={s.jPills}>
          {tl.map((l,i)=>{
            const col=db?lineCol(l.line?.name):modeCol(l.mode);
            const lbl=db?(l.line?.name||'?'):(l.routeShortName||l.displayName||'?');
            return <React.Fragment key={i}>{i>0&&<Text style={s.jArr}>›</Text>}<Pill label={lbl} color={col}/></React.Fragment>;
          })}
          <View style={{flex:1}}/>
          {onSave&&(
            <TouchableOpacity onPress={onSave} hitSlop={{top:10,bottom:10,left:10,right:10}}>
              <Text style={{fontSize:20}}>{saved?'🔖':'📌'}</Text>
            </TouchableOpacity>
          )}
        </View>

        <View style={s.jChev}>
          <Text style={s.jChevTxt}>{open?'▲ Schließen':'▼ Reiseplan & Umstieg'}</Text>
        </View>
      </TouchableOpacity>
      {open&&<Timeline j={j} db={db}/>}
    </View>
  );
}

/* ═══ SCREEN: SUCHEN ═══ */
function SearchScreen({saved, setSaved}){
  const now = new Date();
  const [ft,setFt]=useState(''); const [tt,setTt]=useState('');
  const [fSt,setFSt]=useState(null); const [tSt,setTSt]=useState(null);
  const [mode,setMode]=useState('dep');
  const [date,setDate]=useState(now.toISOString().slice(0,10));
  const [time,setTime]=useState(now.toTimeString().slice(0,5));
  const [loading,setLoading]=useState(false);
  const [results,setResults]=useState(null);
  const [db,setDb]=useState(true);

  const jId = (j,isDb) => { const tl=transitLegs(j,isDb); return `${fSt?.id}-${tSt?.id}-${legDep(tl[0],isDb)}`; };
  const isSaved = (j,isDb) => saved.some(s=>s.id===jId(j,isDb));

  const toggleSave = (j,isDb) => {
    const id=jId(j,isDb);
    const exists=saved.some(s=>s.id===id);
    const upd=exists?saved.filter(s=>s.id!==id):[{id,j,db:isDb,fromName:ft,toName:tt,fSt,tSt,at:new Date().toISOString()},...saved];
    setSaved(upd); AsyncStorage.setItem('zugJ',JSON.stringify(upd));
  };

  const search = async () => {
    if(!fSt||!tSt){Alert.alert('Tipp','Bitte Station aus der Liste auswählen.');return;}
    Keyboard.dismiss(); setLoading(true); setResults(null);
    const when=new Date(`${date}T${time}:00`).toISOString();
    const arrBy=mode==='arr';
    if(dbOk&&fSt._db&&tSt._db){
      try{
        const p=new URLSearchParams({from:fSt.id,to:tSt.id,results:'8',stopovers:'false',remarks:'false',language:'de'});
        p.set(arrBy?'arrival':'departure',when);
        const r=await fetch(`${DB}/journeys?${p}`,{signal:AbortSignal.timeout(8000)});
        if(r.ok){const d=await r.json();setResults(d.journeys||[]);setDb(true);setLoading(false);return;}
      }catch{dbOk=false;}
    }
    try{
      const p=new URLSearchParams({fromPlace:`${fSt.lat},${fSt.lon}`,toPlace:`${tSt.lat},${tSt.lon}`,time:when,arriveBy:String(arrBy),numItineraries:'8'});
      const r=await fetch(`${PLAN}?${p}`);
      if(!r.ok)throw new Error(`Fehler ${r.status}`);
      const d=await r.json(); setResults(d.itineraries||[]); setDb(false);
    }catch(e){Alert.alert('Fehler',e.message);}
    setLoading(false);
  };

  return (
    <ScrollView style={s.screen} contentContainerStyle={s.scroll} keyboardShouldPersistTaps="handled">
      <Text style={s.bigTitle}>Verbindungen</Text>

      <View style={s.card}>
        <StationInput placeholder="Von wo?" value={ft} onChange={setFt}
          onSelect={x=>{setFSt(x);setFt(x.name);}} dotColor={C.green}/>
        <View style={s.swapRow}>
          <View style={s.swapLine}/>
          <TouchableOpacity style={s.swapBtn} onPress={()=>{setFt(tt);setTt(ft);setFSt(tSt);setTSt(fSt);}}>
            <Text style={{fontSize:16,color:C.label2}}>⇅</Text>
          </TouchableOpacity>
          <View style={s.swapLine}/>
        </View>
        <StationInput placeholder="Wohin?" value={tt} onChange={setTt}
          onSelect={x=>{setTSt(x);setTt(x.name);}} dotColor={C.brand}/>
      </View>

      <View style={[s.card,{flexDirection:'row',padding:0,overflow:'hidden'}]}>
        <TouchableOpacity style={s.tSeg} onPress={()=>setMode(m=>m==='dep'?'arr':'dep')}>
          <Text style={s.tSegTxt}>{mode==='dep'?'🚂 Abfahrt':'🏁 Ankunft'}</Text>
        </TouchableOpacity>
        <View style={s.tDiv}/>
        <TextInput style={[s.tSeg,{fontSize:14,color:C.label,textAlign:'center'}]} value={date} onChangeText={setDate}
          placeholder="JJJJ-MM-TT" placeholderTextColor={C.label3} keyboardType="numbers-and-punctuation"/>
        <View style={s.tDiv}/>
        <TextInput style={[s.tSeg,{fontSize:14,color:C.label,textAlign:'center'}]} value={time} onChangeText={setTime}
          placeholder="HH:MM" placeholderTextColor={C.label3} keyboardType="numbers-and-punctuation"/>
      </View>

      <TouchableOpacity style={[s.cta,loading&&{opacity:.5}]} onPress={search} disabled={loading} activeOpacity={0.85}>
        {loading?<ActivityIndicator color="#fff"/>:<Text style={s.ctaTxt}>Suchen</Text>}
      </TouchableOpacity>

      {results!==null&&(
        <View>
          <SectionHdr title={`${results.length} Verbindungen`} right={db?'● DB Live':'● Transitous'}/>
          {results.length===0
            ?<View style={s.empty}><Text style={s.emptyIco}>🔍</Text><Text style={s.emptyTxt}>Keine Verbindungen</Text></View>
            :results.map((j,i)=><JCard key={i} j={j} db={db} fromName={ft} toName={tt}
                onSave={()=>toggleSave(j,db)} saved={isSaved(j,db)}/>)
          }
        </View>
      )}
    </ScrollView>
  );
}

/* ═══ SCREEN: ABFAHRTEN ═══ */
function AbfahrtenScreen({openSt}){
  const [stTxt,setStTxt]=useState('');
  const [st,setSt]=useState(null);
  const [deps,setDeps]=useState(null);
  const [type,setType]=useState(null);
  const [loading,setLoading]=useState(false);
  const [updAt,setUpdAt]=useState(null);
  const [favs,setFavs]=useState([]);
  const ref=useRef(null);

  useEffect(()=>{AsyncStorage.getItem('zugFavs').then(v=>{if(v)setFavs(JSON.parse(v));});},[]);
  useEffect(()=>{if(openSt){setStTxt(openSt.name);setSt(openSt);loadDeps(openSt);}},[openSt?.id]);
  useEffect(()=>()=>clearInterval(ref.current),[]);

  const saveFavs=f=>{setFavs(f);AsyncStorage.setItem('zugFavs',JSON.stringify(f));};
  const isFav=id=>favs.some(f=>f.id===id);
  const toggleFav=()=>{
    if(!st)return;
    const f=isFav(st.id)?favs.filter(x=>x.id!==st.id):[{id:st.id,name:st.name,icon:st.icon||'🚉',_db:st._db,lat:st.lat,lon:st.lon,products:st.products,modes:st.modes},...favs];
    saveFavs(f);
  };

  const loadDeps=async station=>{
    setLoading(true);setDeps(null);
    if(dbOk&&station._db){
      try{
        const r=await fetch(`${DB}/stops/${encodeURIComponent(station.id)}/departures?results=30&duration=120`,{signal:AbortSignal.timeout(6000)});
        if(r.ok){const d=await r.json();setDeps(d.departures||d);setType('db');setUpdAt(new Date());setLoading(false);
          clearInterval(ref.current);ref.current=setInterval(()=>refresh(station),60000);return;}
      }catch{dbOk=false;}
    }
    try{
      const r=await fetch(`${DEPS}?stopId=${encodeURIComponent(station.id)}&n=30&time=${new Date().toISOString()}`);
      if(!r.ok)throw new Error();
      const d=await r.json();setDeps(d.stopTimes||[]);setType('t');setUpdAt(new Date());
    }catch{Alert.alert('Fehler','Abfahrten konnten nicht geladen werden.');}
    setLoading(false);
    clearInterval(ref.current);ref.current=setInterval(()=>refresh(station),60000);
  };

  const refresh=async station=>{
    try{
      if(dbOk&&station._db){
        const r=await fetch(`${DB}/stops/${encodeURIComponent(station.id)}/departures?results=30&duration=120`,{signal:AbortSignal.timeout(6000)});
        if(r.ok){const d=await r.json();setDeps(d.departures||d);setUpdAt(new Date());return;}
      }
      const r=await fetch(`${DEPS}?stopId=${encodeURIComponent(station.id)}&n=30&time=${new Date().toISOString()}`);
      if(r.ok){const d=await r.json();setDeps(d.stopTimes||[]);setUpdAt(new Date());}
    }catch{}
  };

  const renderDep=(dep,i)=>{
    if(type==='db'){
      const col=lineCol(dep.line?.name);
      const t=dep.when||dep.plannedWhen;
      const d=dly(dep.plannedWhen,dep.when);
      const pl=dep.platform||dep.plannedPlatform;
      return(
        <View key={i} style={[s.depRow,i>0&&s.depSep]}>
          <Pill label={dep.line?.name||'?'} color={col}/>
          <View style={s.depMid}>
            <Text style={s.depDest} numberOfLines={1}>{dep.direction||'?'}</Text>
            {pl&&<Text style={s.depSub}>Gleis {pl}</Text>}
          </View>
          <View style={{alignItems:'flex-end'}}>
            <Text style={s.depTime}>{fmt(t)}</Text>
            {d!==0&&<Text style={[s.depDly,{color:d>0?C.red:C.green}]}>{d>0?`+${d} min`:'✓'}</Text>}
          </View>
        </View>
      );
    }
    const col=modeCol(dep.mode);
    const n=dep.routeShortName||dep.displayName||'?';
    const t=dep.place?.departure;
    const d=dep.realTime?dly(dep.place?.scheduledDeparture,t):0;
    const tr=dep.place?.track;
    return(
      <View key={i} style={[s.depRow,i>0&&s.depSep]}>
        <Pill label={n} color={col}/>
        <View style={s.depMid}>
          <Text style={s.depDest} numberOfLines={1}>{dep.headsign||'?'}</Text>
          {tr&&<Text style={s.depSub}>Gleis {tr}</Text>}
        </View>
        <View style={{alignItems:'flex-end'}}>
          <Text style={s.depTime}>{fmt(t)}</Text>
          {dep.realTime&&d!==0&&<Text style={[s.depDly,{color:d>0?C.red:C.green}]}>{d>0?`+${d} min`:'✓'}</Text>}
        </View>
      </View>
    );
  };

  return(
    <ScrollView style={s.screen} contentContainerStyle={s.scroll} keyboardShouldPersistTaps="handled">
      <Text style={s.bigTitle}>Abfahrten</Text>
      <View style={s.card}>
        <StationInput placeholder="Bahnhof oder Haltestelle…" value={stTxt}
          onChange={v=>{setStTxt(v);if(!v){setSt(null);setDeps(null);}}}
          onSelect={x=>{setSt(x);setStTxt(x.name);loadDeps(x);}} dotColor={C.blue}/>
      </View>
      {loading&&<ActivityIndicator style={{marginTop:40}} size="large" color={C.brand}/>}
      {st&&deps&&(
        <>
          <View style={s.stHdr}>
            <View style={{flex:1}}>
              <Text style={s.stName}>{st.name}</Text>
              {updAt&&(
                <View style={{flexDirection:'row',alignItems:'center',marginTop:4,gap:5}}>
                  <View style={{width:7,height:7,borderRadius:4,backgroundColor:C.green}}/>
                  <Text style={s.updTxt}>Aktuell · {updAt.toLocaleTimeString('de-DE',{hour:'2-digit',minute:'2-digit'})} Uhr</Text>
                </View>
              )}
            </View>
            <View style={{flexDirection:'row',gap:14,alignItems:'center'}}>
              <TouchableOpacity onPress={()=>loadDeps(st)}><Text style={{fontSize:20}}>🔄</Text></TouchableOpacity>
              <TouchableOpacity onPress={toggleFav}>
                <Text style={{fontSize:26,color:isFav(st.id)?C.orange:C.label3}}>{isFav(st.id)?'★':'☆'}</Text>
              </TouchableOpacity>
            </View>
          </View>
          <View style={s.card}>
            {deps.length===0
              ?<Text style={{padding:20,color:C.label2,textAlign:'center'}}>Keine Abfahrten</Text>
              :deps.map((d,i)=>renderDep(d,i))
            }
          </View>
        </>
      )}
    </ScrollView>
  );
}

/* ═══ Live Journey Status Hook ═══ */
function useStatus(j, db){
  const [tick,setTick]=useState(0);
  useEffect(()=>{const t=setInterval(()=>setTick(n=>n+1),1000);return()=>clearInterval(t);},[]);

  const now=Date.now();
  const tl=transitLegs(j,db);
  if(!tl.length) return {phase:'unknown'};

  const firstDep=new Date(legDep(tl[0],db)).getTime();
  const lastArr =new Date(legArr(tl[tl.length-1],db)).getTime();

  if(now>lastArr) return {phase:'done'};

  if(now<firstDep){
    const mins=Math.ceil((firstDep-now)/60000);
    const l=tl[0];
    const plat=db?(l.departurePlatform||l.plannedDeparturePlatform):l.from?.track;
    const line=db?l.line?.name:(l.routeShortName||l.displayName);
    const from_=db?l.origin?.name:l.from?.name;
    return {phase:'soon',mins,plat,line,from:from_};
  }

  for(let i=0;i<tl.length;i++){
    const dep=new Date(legDep(tl[i],db)).getTime();
    const arr=new Date(legArr(tl[i],db)).getTime();
    if(now>=dep&&now<=arr){
      const line=db?tl[i].line?.name:(tl[i].routeShortName||tl[i].displayName);
      const to_=db?tl[i].destination?.name:tl[i].to?.name;
      const aPlat=db?(tl[i].arrivalPlatform||tl[i].plannedArrivalPlatform):tl[i].to?.track;
      return {phase:'riding',line,to:to_,arrTime:legArr(tl[i],db),plat:aPlat};
    }
    if(i<tl.length-1){
      const nextDep=new Date(legDep(tl[i+1],db)).getTime();
      if(now>arr&&now<nextDep){
        const mins=Math.ceil((nextDep-now)/60000);
        const line=db?tl[i+1].line?.name:(tl[i+1].routeShortName||tl[i+1].displayName);
        const plat=db?(tl[i+1].departurePlatform||tl[i+1].plannedDeparturePlatform):tl[i+1].from?.track;
        const at=db?tl[i].destination?.name:tl[i].to?.name;
        return {phase:'xfer',mins,line,plat,at};
      }
    }
  }
  return {phase:'unknown'};
}

/* ═══ Saved Journey Card ═══ */
function SavedCard({item,onDelete}){
  const {j,db,fromName,toName}=item;
  const [open,setOpen]=useState(false);
  const st=useStatus(j,db);
  const tl=transitLegs(j,db);
  if(!tl.length) return null;

  const depT=legDep(tl[0],db);
  const arrT=legArr(tl[tl.length-1],db);
  const chg=tl.length-1;

  let bannerBg=C.fill, bannerIcon='📅', bannerTxt='';
  if(st.phase==='soon'){
    bannerBg=st.mins<=5?C.brandSoft:st.mins<=15?C.orangeSoft:C.greenSoft;
    bannerIcon=st.mins<=5?'🚨':st.mins<=15?'⚡':'📍';
    bannerTxt=`Abfahrt in ${st.mins} min${st.plat?` · Gleis ${st.plat}`:''}${st.line?` · ${st.line}`:''}`;
  } else if(st.phase==='riding'){
    bannerBg=C.greenSoft; bannerIcon='🚆';
    bannerTxt=`Im Zug${st.line?` ${st.line}`:''} · Ankunft ${fmt(st.arrTime)}${st.plat?` Gl. ${st.plat}`:''}`;
  } else if(st.phase==='xfer'){
    bannerBg=st.mins<=3?C.brandSoft:C.orangeSoft;
    bannerIcon=st.mins<=3?'🏃':'⏱';
    bannerTxt=`Umsteigen in ${st.at} · ${st.line} in ${st.mins} min${st.plat?` · Gl. ${st.plat}`:''}`;
  } else if(st.phase==='done'){
    bannerBg='#F2F2F7'; bannerIcon='✓';
    bannerTxt='Reise abgeschlossen';
  }

  return(
    <View style={s.savedCard}>
      {bannerTxt?(
        <View style={[s.banner,{backgroundColor:bannerBg}]}>
          <Text style={s.bannerIco}>{bannerIcon}</Text>
          <Text style={[s.bannerTxt,{color:st.phase==='done'?C.label3:C.label}]} numberOfLines={2}>{bannerTxt}</Text>
        </View>
      ):null}
      <TouchableOpacity onPress={()=>setOpen(o=>!o)} activeOpacity={0.9}>
        <View style={s.savedMain}>
          <View style={{flex:1}}>
            <Text style={s.savedRoute} numberOfLines={1}>{fromName} → {toName}</Text>
            <Text style={s.savedSub}>{fmt(depT)} – {fmt(arrT)} · {chg===0?'Direkt':`${chg}× Umstieg`}</Text>
            <View style={{flexDirection:'row',flexWrap:'wrap',gap:5,marginTop:8}}>
              {tl.map((l,i)=>{
                const col=db?lineCol(l.line?.name):modeCol(l.mode);
                const lbl=db?(l.line?.name||'?'):(l.routeShortName||l.displayName||'?');
                return <React.Fragment key={i}>{i>0&&<Text style={{color:C.label3,fontSize:11}}>›</Text>}<Pill label={lbl} color={col}/></React.Fragment>;
              })}
            </View>
          </View>
          <TouchableOpacity onPress={onDelete} hitSlop={{top:12,bottom:12,left:12,right:12}} style={{paddingLeft:12}}>
            <Text style={{fontSize:18,color:C.label3}}>✕</Text>
          </TouchableOpacity>
        </View>
        <View style={s.jChev}>
          <Text style={s.jChevTxt}>{open?'▲ Schließen':'▼ Reiseplan anzeigen'}</Text>
        </View>
      </TouchableOpacity>
      {open&&<Timeline j={j} db={db}/>}
    </View>
  );
}

/* ═══ SCREEN: MEINE REISEN ═══ */
function ReisenScreen({saved, setSaved}){
  const now=new Date();
  const active=saved.filter(s=>{
    const tl=transitLegs(s.j,s.db);
    return tl.length&&new Date(legArr(tl[tl.length-1],s.db))>now;
  });
  const past=saved.filter(s=>!active.includes(s));

  const del=id=>{
    const upd=saved.filter(s=>s.id!==id);
    setSaved(upd); AsyncStorage.setItem('zugJ',JSON.stringify(upd));
  };

  return(
    <ScrollView style={s.screen} contentContainerStyle={s.scroll}>
      <Text style={s.bigTitle}>Meine Reisen</Text>
      {saved.length===0?(
        <View style={s.empty}>
          <Text style={s.emptyIco}>🎫</Text>
          <Text style={s.emptyTxt}>Keine gespeicherten Reisen</Text>
          <Text style={s.emptySub}>Verbindung suchen → 📌 tippen</Text>
        </View>
      ):(
        <>
          {active.length>0&&(
            <>
              <SectionHdr title="Aktiv & Bevorstehend"/>
              {active.map(s=><SavedCard key={s.id} item={s} onDelete={()=>del(s.id)}/>)}
            </>
          )}
          {past.length>0&&(
            <>
              <SectionHdr title="Abgeschlossen"/>
              {past.map(s=><SavedCard key={s.id} item={s} onDelete={()=>del(s.id)}/>)}
            </>
          )}
        </>
      )}
    </ScrollView>
  );
}

/* ═══ SCREEN: FAVORITEN ═══ */
function FavScreen({onOpen}){
  const [favs,setFavs]=useState([]);
  useEffect(()=>{
    const load=()=>AsyncStorage.getItem('zugFavs').then(v=>setFavs(v?JSON.parse(v):[]));
    load(); const t=setInterval(load,3000); return()=>clearInterval(t);
  },[]);
  const remove=id=>{const f=favs.filter(x=>x.id!==id);setFavs(f);AsyncStorage.setItem('zugFavs',JSON.stringify(f));};

  return(
    <ScrollView style={s.screen} contentContainerStyle={s.scroll}>
      <Text style={s.bigTitle}>Favoriten</Text>
      {favs.length===0?(
        <View style={s.empty}>
          <Text style={s.emptyIco}>⭐</Text>
          <Text style={s.emptyTxt}>Keine Favoriten</Text>
          <Text style={s.emptySub}>Unter Abfahrten ☆ → ★ tippen</Text>
        </View>
      ):(
        <>
          <SectionHdr title="Gespeicherte Bahnhöfe"/>
          <View style={s.card}>
            {favs.map((f,i)=>(
              <TouchableOpacity key={f.id} style={[s.favRow,i>0&&s.depSep]} onPress={()=>onOpen(f)} activeOpacity={0.7}>
                <View style={s.favIco}><Text style={{fontSize:22}}>{f.icon||'🚉'}</Text></View>
                <View style={{flex:1}}>
                  <Text style={s.favName}>{f.name}</Text>
                  <Text style={s.favSub}>Abfahrtsplan öffnen →</Text>
                </View>
                <TouchableOpacity onPress={()=>remove(f.id)} hitSlop={{top:10,bottom:10,left:10,right:10}}>
                  <Text style={{fontSize:18,color:C.label3}}>✕</Text>
                </TouchableOpacity>
              </TouchableOpacity>
            ))}
          </View>
        </>
      )}
    </ScrollView>
  );
}

/* ═══ TAB BAR ═══ */
const TABS=[
  {key:'search',label:'Suchen',   ico:'🔍'},
  {key:'dep',   label:'Abfahrten',ico:'🕑'},
  {key:'reisen',label:'Reisen',   ico:'🎫'},
  {key:'favs',  label:'Favoriten',ico:'⭐'},
];

function TabBar({active,onChange,badge}){
  return(
    <View style={s.tabBar}>
      {TABS.map(t=>{
        const on=active===t.key;
        return(
          <TouchableOpacity key={t.key} style={s.tabItem} onPress={()=>onChange(t.key)} activeOpacity={0.7}>
            <View style={{position:'relative'}}>
              <Text style={[s.tabIco,{opacity:on?1:.4}]}>{t.ico}</Text>
              {(badge[t.key]||0)>0&&(
                <View style={s.badge}>
                  <Text style={s.badgeTxt}>{badge[t.key]}</Text>
                </View>
              )}
            </View>
            <Text style={[s.tabLbl,{color:on?C.brand:C.label3,fontWeight:on?'700':'500'}]}>{t.label}</Text>
          </TouchableOpacity>
        );
      })}
    </View>
  );
}

/* ═══ ROOT ═══ */
export default function App(){
  const [tab,setTab]=useState('search');
  const [openSt,setOpenSt]=useState(null);
  const [saved,setSaved]=useState([]);

  useEffect(()=>{AsyncStorage.getItem('zugJ').then(v=>{if(v)setSaved(JSON.parse(v));});},[]);

  const now=new Date();
  const activeCnt=saved.filter(s=>{
    const tl=transitLegs(s.j,s.db);
    return tl.length&&new Date(legArr(tl[tl.length-1],s.db))>now;
  }).length;

  return(
    <SafeAreaView style={{flex:1,backgroundColor:C.bg}}>
      <StatusBar barStyle="dark-content"/>
      <View style={{flex:1}}>
        {tab==='search'&&<SearchScreen saved={saved} setSaved={setSaved}/>}
        {tab==='dep'   &&<AbfahrtenScreen openSt={openSt}/>}
        {tab==='reisen'&&<ReisenScreen saved={saved} setSaved={setSaved}/>}
        {tab==='favs'  &&<FavScreen onOpen={st=>{setOpenSt(st);setTab('dep');}}/>}
      </View>
      <TabBar active={tab} onChange={setTab} badge={{reisen:activeCnt}}/>
    </SafeAreaView>
  );
}

/* ═══ STYLES ═══ */
const sh=Platform.select({
  ios:{shadowColor:'#000',shadowOffset:{width:0,height:1},shadowOpacity:.07,shadowRadius:5},
  android:{elevation:2},
});

const s=StyleSheet.create({
  screen:{flex:1,backgroundColor:C.bg},
  scroll:{padding:16,paddingBottom:32},
  bigTitle:{fontSize:34,fontWeight:'800',letterSpacing:0.37,marginBottom:20,marginTop:4,color:C.label},

  card:{backgroundColor:C.card,borderRadius:14,marginBottom:12,...sh},
  sepLine:{height:StyleSheet.hairlineWidth,backgroundColor:C.sep,marginLeft:16},

  sHdr:{flexDirection:'row',alignItems:'baseline',justifyContent:'space-between',marginBottom:10,paddingHorizontal:4},
  sHdrTxt:{fontSize:13,fontWeight:'600',color:C.label2,textTransform:'uppercase',letterSpacing:.5},
  sHdrRight:{fontSize:12,color:C.green,fontWeight:'600'},

  inputRow:{flexDirection:'row',alignItems:'center',paddingHorizontal:16,paddingVertical:14,gap:12,minHeight:52},
  inputDot:{width:10,height:10,borderRadius:5,flexShrink:0},
  inputTxt:{flex:1,fontSize:17,color:C.label},

  drop:{
    position:'absolute',top:'100%',left:0,right:0,zIndex:9999,
    backgroundColor:C.card,borderRadius:14,overflow:'hidden',marginTop:4,
    ...Platform.select({ios:{shadowColor:'#000',shadowOffset:{width:0,height:6},shadowOpacity:.16,shadowRadius:20},android:{elevation:10}}),
  },
  dropRow:{flexDirection:'row',alignItems:'center',paddingHorizontal:16,paddingVertical:13,gap:12,minHeight:50},
  dropSep:{borderTopWidth:StyleSheet.hairlineWidth,borderTopColor:C.sep},
  dropIco:{fontSize:20,width:28,textAlign:'center'},
  dropName:{fontSize:16,color:C.label,flex:1},

  swapRow:{flexDirection:'row',alignItems:'center',paddingHorizontal:16,height:28},
  swapLine:{flex:1,height:StyleSheet.hairlineWidth,backgroundColor:C.sep},
  swapBtn:{width:30,height:30,borderRadius:15,backgroundColor:C.fill,alignItems:'center',justifyContent:'center',marginHorizontal:8},

  tSeg:{flex:1,padding:14,alignItems:'center',justifyContent:'center'},
  tSegTxt:{fontSize:14,fontWeight:'600',color:C.label,textAlign:'center'},
  tDiv:{width:StyleSheet.hairlineWidth,backgroundColor:C.sep},

  cta:{backgroundColor:C.brand,borderRadius:14,paddingVertical:16,alignItems:'center',marginBottom:20,
    ...Platform.select({ios:{shadowColor:C.brand,shadowOffset:{width:0,height:5},shadowOpacity:.4,shadowRadius:12},android:{elevation:6}})},
  ctaTxt:{color:'#fff',fontSize:17,fontWeight:'800',letterSpacing:.3},

  jCard:{backgroundColor:C.card,borderRadius:14,marginBottom:10,overflow:'hidden',...sh},
  jTop:{flexDirection:'row',alignItems:'flex-start',padding:16,paddingBottom:10},
  jCol:{flex:1},
  jTimeLg:{fontSize:26,fontWeight:'800',letterSpacing:-.5,color:C.label},
  jDly:{fontSize:12,fontWeight:'700',marginTop:3},
  jMid:{alignItems:'center',flex:1,paddingHorizontal:8},
  jDurTxt:{fontSize:12,color:C.label2,fontWeight:'600',marginBottom:5},
  jBar:{width:60,height:2,backgroundColor:'#D1D1D6',borderRadius:2,position:'relative',marginVertical:2},
  jBarDot:{position:'absolute',width:7,height:7,borderRadius:3.5,top:-2.5},
  jChgTxt:{fontSize:11,color:C.label2,marginTop:5},
  jNames:{flexDirection:'row',justifyContent:'space-between',paddingHorizontal:16,marginBottom:10},
  jNameTxt:{fontSize:11,color:C.label2,flex:1},
  jPills:{flexDirection:'row',flexWrap:'wrap',gap:5,paddingHorizontal:16,paddingBottom:10,alignItems:'center'},
  jArr:{fontSize:11,color:C.label3},
  jChev:{borderTopWidth:StyleSheet.hairlineWidth,borderTopColor:C.sep,alignItems:'center',paddingVertical:9},
  jChevTxt:{fontSize:12,color:C.label3,fontWeight:'500'},

  platChip:{backgroundColor:'#E5E5EA',borderRadius:6,paddingHorizontal:8,paddingVertical:3},
  platChipTxt:{fontSize:11,fontWeight:'800',color:C.label2},
  dlyTag:{fontSize:12,fontWeight:'800'},

  timeline:{padding:16,paddingTop:8,backgroundColor:'#F9F9FB'},
  tlRow:{flexDirection:'row'},
  tlLeft:{width:28,alignItems:'center',flexShrink:0,paddingTop:2},
  tlDot:{width:12,height:12,borderRadius:6,zIndex:1},
  tlLineV:{width:2,flex:1,minHeight:36,borderRadius:2,marginVertical:2},
  tlContent:{flex:1,paddingLeft:10,paddingBottom:16},
  tlTR:{flexDirection:'row',alignItems:'center',gap:8,marginBottom:3,flexWrap:'wrap'},
  tlTime:{fontSize:16,fontWeight:'800',color:C.label},
  tlStation:{fontSize:14,fontWeight:'600',color:C.label},
  tlPR:{flexDirection:'row',alignItems:'center',gap:8,marginTop:6},
  tlDir:{fontSize:13,color:C.label2,flex:1},
  tlWalkRow:{flexDirection:'row',alignItems:'center',paddingBottom:12},
  tlWalkLine:{width:2,height:20,backgroundColor:'#D1D1D6',borderRadius:2},
  tlWalkBadge:{backgroundColor:C.fill,borderRadius:10,paddingHorizontal:12,paddingVertical:5,marginLeft:8},
  tlWalkTxt:{fontSize:13,color:C.label2},
  tlXferRow:{flexDirection:'row',alignItems:'center',paddingBottom:14},
  xferChip:{flex:1,borderRadius:10,paddingHorizontal:12,paddingVertical:7,marginLeft:0},
  xferTxt:{fontSize:13,fontWeight:'700'},

  stHdr:{flexDirection:'row',alignItems:'flex-start',justifyContent:'space-between',paddingHorizontal:4,marginBottom:12,marginTop:4},
  stName:{fontSize:22,fontWeight:'800',letterSpacing:-.3,color:C.label},
  updTxt:{fontSize:12,color:C.label2},

  depRow:{flexDirection:'row',alignItems:'center',paddingHorizontal:16,paddingVertical:13,gap:12,minHeight:58},
  depSep:{borderTopWidth:StyleSheet.hairlineWidth,borderTopColor:C.sep},
  depMid:{flex:1,minWidth:0},
  depDest:{fontSize:16,fontWeight:'500',color:C.label},
  depSub:{fontSize:12,color:C.label2,marginTop:3},
  depTime:{fontSize:18,fontWeight:'800',letterSpacing:-.3,color:C.label},
  depDly:{fontSize:12,fontWeight:'700',marginTop:2},

  savedCard:{backgroundColor:C.card,borderRadius:14,marginBottom:10,overflow:'hidden',...sh},
  banner:{flexDirection:'row',alignItems:'center',paddingHorizontal:16,paddingVertical:12,gap:10},
  bannerIco:{fontSize:22},
  bannerTxt:{fontSize:14,fontWeight:'700',flex:1,lineHeight:20},
  savedMain:{flexDirection:'row',alignItems:'flex-start',padding:16,paddingBottom:10},
  savedRoute:{fontSize:17,fontWeight:'800',color:C.label,marginBottom:4},
  savedSub:{fontSize:13,color:C.label2},

  favRow:{flexDirection:'row',alignItems:'center',paddingHorizontal:16,paddingVertical:13,minHeight:58},
  favIco:{width:42,height:42,borderRadius:11,backgroundColor:C.brandSoft,alignItems:'center',justifyContent:'center',marginRight:12},
  favName:{fontSize:16,fontWeight:'600',color:C.label},
  favSub:{fontSize:13,color:C.label2,marginTop:2},

  empty:{alignItems:'center',paddingVertical:64},
  emptyIco:{fontSize:56,marginBottom:14},
  emptyTxt:{fontSize:17,fontWeight:'600',color:C.label2},
  emptySub:{fontSize:14,color:C.label3,marginTop:8,textAlign:'center',paddingHorizontal:32},

  pill:{paddingHorizontal:9,paddingVertical:4,borderRadius:7},
  pillTxt:{color:'#fff',fontSize:12,fontWeight:'800',letterSpacing:.2},

  tabBar:{
    flexDirection:'row',backgroundColor:'rgba(249,249,249,.97)',
    borderTopWidth:StyleSheet.hairlineWidth,borderTopColor:C.sep,
    paddingBottom:Platform.OS==='ios'?24:6,
    ...Platform.select({ios:{shadowColor:'#000',shadowOffset:{width:0,height:-1},shadowOpacity:.06,shadowRadius:0}}),
  },
  tabItem:{flex:1,alignItems:'center',paddingTop:10,paddingBottom:2},
  tabIco:{fontSize:24},
  tabLbl:{fontSize:10,marginTop:3,letterSpacing:.1},
  badge:{position:'absolute',top:-5,right:-10,backgroundColor:C.brand,borderRadius:8,minWidth:17,height:17,alignItems:'center',justifyContent:'center',paddingHorizontal:3,borderWidth:2,borderColor:'rgba(249,249,249,.97)'},
  badgeTxt:{color:'#fff',fontSize:10,fontWeight:'800'},
});
