import React, { useState, useRef, useCallback, useEffect } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, ScrollView,
  StyleSheet, Platform, SafeAreaView, StatusBar,
  ActivityIndicator, Alert, Keyboard, Pressable,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

/* ─── APIs ─── */
const DB    = 'https://v6.db.transport.rest';
const GEO   = 'https://api.transitous.org/api/v1/geocode';
const PLAN  = 'https://api.transitous.org/api/v3/plan';
const DEPST = 'https://api.transitous.org/api/v1/stoptimes';

/* ─── iOS Farben ─── */
const C = {
  bg: '#F2F2F7', card: '#FFFFFF',
  label: '#000', label2: 'rgba(60,60,67,.6)', label3: 'rgba(60,60,67,.3)',
  sep: 'rgba(60,60,67,.12)', fill: 'rgba(120,120,128,.12)',
  blue: '#007AFF', red: '#FF3B30', green: '#34C759',
  orange: '#FF9500', brand: '#EC0016',
};

/* ─── Hilfsfunktionen ─── */
const fmtTime = iso => iso
  ? new Date(iso).toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' })
  : '--:--';

const fmtDur = s => {
  if (!s || s < 0) return '?';
  const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
  return h > 0 ? `${h}h ${m}min` : `${m} min`;
};

const delayMin = (a, b) => (a && b) ? Math.round((new Date(b) - new Date(a)) / 60000) : 0;

const lineCol = name => {
  if (!name) return '#8E8E93';
  const n = name.toUpperCase();
  if (/ICE/.test(n)) return '#EC0016';
  if (/^IC|^EC/.test(n)) return '#C4000F';
  if (/^RE|^RB/.test(n)) return '#0066CC';
  if (/^S\d/.test(n)) return '#007E3C';
  if (/^U\d/.test(n)) return '#1C4B9B';
  if (/STR|^T\d|^M\d/.test(n)) return '#C0003C';
  if (/BUS|NB/.test(n)) return '#7C3AED';
  return '#555';
};

const modeCol = mode => {
  switch ((mode || '').toUpperCase()) {
    case 'HIGHSPEED_RAIL': return '#EC0016';
    case 'LONG_DISTANCE':  return '#C4000F';
    case 'REGIONAL_FAST_RAIL': case 'REGIONAL_RAIL': case 'RAIL': return '#0066CC';
    case 'SUBURBAN': case 'METRO': case 'SUBWAY': return '#007E3C';
    case 'TRAM': return '#C0003C';
    case 'BUS': case 'COACH': return '#7C3AED';
    default: return '#8E8E93';
  }
};

const stIcon = (products, modes) => {
  if (products) {
    if (products.nationalExpress || products.national) return '🚄';
    if (products.regionalExpress || products.regional) return '🚆';
    if (products.suburban) return '🚊';
    if (products.subway) return '🚇';
    if (products.tram) return '🚋';
    if (products.bus) return '🚌';
  }
  if (modes) {
    if (modes.includes('HIGHSPEED_RAIL') || modes.includes('LONG_DISTANCE')) return '🚄';
    if (modes.includes('REGIONAL_RAIL')) return '🚆';
    if (modes.includes('SUBURBAN')) return '🚊';
    if (modes.includes('SUBWAY') || modes.includes('METRO')) return '🚇';
    if (modes.includes('TRAM')) return '🚋';
    if (modes.includes('BUS')) return '🚌';
  }
  return '🚉';
};

/* ─── Kleine Komponenten ─── */
const Pill = ({ label, color }) => (
  <View style={[s.pill, { backgroundColor: color }]}>
    <Text style={s.pillTxt}>{label}</Text>
  </View>
);

const Delay = ({ d }) => (
  <Text style={[s.delay, { color: d <= 0 ? C.green : C.red }]}>
    {d <= 0 ? 'pünktlich' : `+${d} min`}
  </Text>
);

const Sep = () => <View style={s.sep} />;

/* ─── Stations-Suche ─── */
let dbOk = true;

function StationInput({ placeholder, value, onChange, onSelect, dotColor }) {
  const [sugs, setSugs] = useState([]);
  const [busy, setBusy] = useState(false);
  const tmr = useRef(null);

  const doFetch = async q => {
    if (q.length < 2) { setSugs([]); return; }
    setBusy(true);
    try {
      if (dbOk) {
        try {
          const r = await fetch(
            `${DB}/locations?query=${encodeURIComponent(q)}&results=10&stops=true&addresses=false&poi=false`,
            { signal: AbortSignal.timeout(5000) }
          );
          if (r.ok) {
            const d = await r.json();
            setSugs((d || []).map(x => ({
              id: x.id, name: x.name,
              lat: x.location?.latitude, lon: x.location?.longitude,
              products: x.products, _db: true, icon: stIcon(x.products),
            })));
            setBusy(false); return;
          }
        } catch { dbOk = false; }
      }
      const r = await fetch(`${GEO}?text=${encodeURIComponent(q)}&language=de`);
      const d = await r.json();
      const RL = ['HIGHSPEED_RAIL','LONG_DISTANCE','REGIONAL_RAIL','SUBURBAN','RAIL'];
      const st = (d || []).filter(x => x.type === 'STOP');
      st.sort((a, b) => {
        const aR = (a.modes||[]).some(m => RL.includes(m));
        const bR = (b.modes||[]).some(m => RL.includes(m));
        if (aR && !bR) return -1; if (!aR && bR) return 1;
        return (b.importance||0)-(a.importance||0);
      });
      setSugs(st.slice(0,10).map(x => ({
        id: x.id, name: x.name, lat: x.lat, lon: x.lon,
        modes: x.modes, _db: false, icon: stIcon(null, x.modes),
      })));
    } catch { setSugs([]); }
    setBusy(false);
  };

  return (
    <View>
      <View style={s.inputRow}>
        <View style={[s.inputDot, { backgroundColor: dotColor }]} />
        <TextInput
          style={s.input}
          placeholder={placeholder}
          placeholderTextColor={C.label3}
          value={value}
          onChangeText={t => {
            onChange(t);
            clearTimeout(tmr.current);
            tmr.current = setTimeout(() => doFetch(t.trim()), 220);
          }}
          autoCorrect={false}
          autoCapitalize="words"
        />
        {busy && <ActivityIndicator size="small" color={C.brand} style={{ marginRight: 12 }} />}
      </View>
      {sugs.length > 0 && (
        <View style={s.sugBox}>
          {sugs.map((x, i) => (
            <TouchableOpacity
              key={x.id + i}
              style={[s.sugRow, i > 0 && s.sugSep]}
              onPress={() => { onChange(x.name); onSelect(x); setSugs([]); Keyboard.dismiss(); }}
              activeOpacity={0.6}
            >
              <Text style={s.sugIco}>{x.icon}</Text>
              <Text style={s.sugName} numberOfLines={1}>{x.name}</Text>
            </TouchableOpacity>
          ))}
        </View>
      )}
    </View>
  );
}

/* ─── Journey Detail ─── */
function LegView({ legs, isDB }) {
  return (
    <View style={s.detailBox}>
      {(legs || []).map((leg, i) => {
        const isLast = i === legs.length - 1;
        if (isDB) {
          if (leg.walking) {
            const m = Math.ceil((new Date(leg.arrival) - new Date(leg.departure)) / 60000);
            return (
              <View key={i} style={s.legRow}>
                <View style={s.legTL}>
                  <View style={[s.legDot, { backgroundColor: C.label3 }]} />
                  <View style={[s.legLine, { backgroundColor: '#D1D1D6' }]} />
                </View>
                <Text style={s.walkTxt}>🚶 {m || 1} min Fußweg</Text>
              </View>
            );
          }
          const col = lineCol(leg.line?.name);
          const dR = leg.departure || leg.plannedDeparture;
          const aR = leg.arrival || leg.plannedArrival;
          const dd = delayMin(leg.plannedDeparture, dR);
          const da = delayMin(leg.plannedArrival, aR);
          const oP = leg.departurePlatform || leg.plannedDeparturePlatform || '';
          const dP = leg.arrivalPlatform || leg.plannedArrivalPlatform || '';
          return (
            <View key={i}>
              <View style={s.legRow}>
                <View style={s.legTL}>
                  <View style={[s.legDot, { backgroundColor: C.green }]} />
                  <View style={[s.legLine, { backgroundColor: col }]} />
                </View>
                <View style={s.legBody}>
                  <View style={s.legTR}>
                    <Text style={s.legTime}>{fmtTime(dR)}</Text>
                    <Delay d={dd} />
                  </View>
                  <Text style={s.legSt}>{leg.origin?.name}</Text>
                  {oP ? <Text style={s.plat}>Gleis {oP}</Text> : null}
                  <View style={s.legLR}>
                    <Pill label={leg.line?.name || '?'} color={col} />
                    <Text style={s.legDir} numberOfLines={1}>Richtung {leg.direction || leg.destination?.name}</Text>
                  </View>
                </View>
              </View>
              {isLast && (
                <View style={s.legRow}>
                  <View style={s.legTL}><View style={[s.legDot, { backgroundColor: C.brand }]} /></View>
                  <View style={s.legBody}>
                    <View style={s.legTR}>
                      <Text style={s.legTime}>{fmtTime(aR)}</Text>
                      <Delay d={da} />
                    </View>
                    <Text style={s.legSt}>{leg.destination?.name}</Text>
                    {dP ? <Text style={s.plat}>Gleis {dP}</Text> : null}
                  </View>
                </View>
              )}
            </View>
          );
        } else {
          if (leg.mode === 'WALK') {
            const m = Math.round((leg.duration || 0) / 60);
            return (
              <View key={i} style={s.legRow}>
                <View style={s.legTL}>
                  <View style={[s.legDot, { backgroundColor: C.label3 }]} />
                  <View style={[s.legLine, { backgroundColor: '#D1D1D6' }]} />
                </View>
                <Text style={s.walkTxt}>🚶 {m || 1} min Fußweg</Text>
              </View>
            );
          }
          const col = modeCol(leg.mode);
          const n = leg.routeShortName || leg.displayName || '?';
          const dR = leg.from?.departure || leg.startTime;
          const aR = leg.to?.arrival || leg.endTime;
          const dd = leg.realTime ? delayMin(leg.from?.scheduledDeparture, dR) : 0;
          const da = leg.realTime ? delayMin(leg.to?.scheduledArrival, aR) : 0;
          const oT = leg.from?.track || '';
          const dT = leg.to?.track || '';
          return (
            <View key={i}>
              <View style={s.legRow}>
                <View style={s.legTL}>
                  <View style={[s.legDot, { backgroundColor: C.green }]} />
                  <View style={[s.legLine, { backgroundColor: col }]} />
                </View>
                <View style={s.legBody}>
                  <View style={s.legTR}>
                    <Text style={s.legTime}>{fmtTime(dR)}</Text>
                    {leg.realTime && <Delay d={dd} />}
                  </View>
                  <Text style={s.legSt}>{leg.from?.name}</Text>
                  {oT ? <Text style={s.plat}>Gleis {oT}</Text> : null}
                  <View style={s.legLR}>
                    <Pill label={n} color={col} />
                    <Text style={s.legDir} numberOfLines={1}>Richtung {leg.headsign || leg.to?.name}</Text>
                  </View>
                </View>
              </View>
              {isLast && (
                <View style={s.legRow}>
                  <View style={s.legTL}><View style={[s.legDot, { backgroundColor: C.brand }]} /></View>
                  <View style={s.legBody}>
                    <View style={s.legTR}>
                      <Text style={s.legTime}>{fmtTime(aR)}</Text>
                      {leg.realTime && <Delay d={da} />}
                    </View>
                    <Text style={s.legSt}>{leg.to?.name}</Text>
                    {dT ? <Text style={s.plat}>Gleis {dT}</Text> : null}
                  </View>
                </View>
              )}
            </View>
          );
        }
      })}
    </View>
  );
}

/* ─── Journey Card ─── */
function JCard({ j, fromName, toName, isDB }) {
  const [open, setOpen] = useState(false);
  const SKIP = ['HIGHSPEED_RAIL','LONG_DISTANCE','NIGHT_RAIL','COACH'];

  let legs, transit, depR, depS, arrR, arrS, dur, chg, pills;

  if (isDB) {
    legs = j.legs || [];
    transit = legs.filter(l => !l.walking);
    if (!transit.length) return null;
    const f = transit[0], la = transit[transit.length - 1];
    depR = f.departure || f.plannedDeparture; depS = f.plannedDeparture;
    arrR = la.arrival || la.plannedArrival;   arrS = la.plannedArrival;
    chg = transit.length - 1;
    dur = (new Date(arrR) - new Date(depR)) / 1000;
    pills = transit.map((l, i) => <Pill key={i} label={l.line?.name || '?'} color={lineCol(l.line?.name)} />);
  } else {
    legs = j.legs || [];
    transit = legs.filter(l => l.mode !== 'WALK');
    if (!transit.length || transit.some(l => SKIP.includes(l.mode))) return null;
    const f = transit[0], la = transit[transit.length - 1];
    depR = f.from?.departure || f.startTime; depS = f.from?.scheduledDeparture || f.scheduledStartTime;
    arrR = la.to?.arrival || la.endTime;     arrS = la.to?.scheduledArrival || la.scheduledEndTime;
    chg = j.transfers ?? Math.max(0, transit.length - 1);
    dur = j.duration;
    pills = transit.map((l, i) => <Pill key={i} label={l.routeShortName || l.displayName || '?'} color={modeCol(l.mode)} />);
  }

  const dDep = delayMin(depS, depR);
  const dArr = delayMin(arrS, arrR);

  return (
    <View style={s.jCard}>
      <TouchableOpacity onPress={() => setOpen(o => !o)} activeOpacity={0.8}>
        <View style={s.jTop}>
          <View style={s.jCol}>
            <Text style={s.jTime}>{fmtTime(depR)}</Text>
            <Delay d={dDep} />
            <Text style={s.jSt} numberOfLines={1}>{fromName}</Text>
          </View>
          <View style={s.jMid}>
            <Text style={s.jDur}>{fmtDur(dur)}</Text>
            <View style={s.jBar}>
              <View style={[s.jDot, { backgroundColor: C.green, left: -3 }]} />
              <View style={[s.jDot, { backgroundColor: C.brand, right: -3 }]} />
            </View>
            <Text style={s.jChg}>{chg === 0 ? 'Direkt' : `${chg} Umst.`}</Text>
          </View>
          <View style={[s.jCol, { alignItems: 'flex-end' }]}>
            <Text style={s.jTime}>{fmtTime(arrR)}</Text>
            <Delay d={dArr} />
            <Text style={[s.jSt, { textAlign: 'right' }]} numberOfLines={1}>{toName}</Text>
          </View>
        </View>
        <View style={s.jPills}>{pills}</View>
        <Sep />
        <View style={s.jChevRow}>
          <Text style={s.jChevTxt}>{open ? 'Schließen ▲' : 'Details ▼'}</Text>
        </View>
      </TouchableOpacity>
      {open && <LegView legs={legs} isDB={isDB} />}
    </View>
  );
}

/* ─── SCREEN: SUCHEN ─── */
function SearchScreen() {
  const now = new Date();
  const [ft, setFt] = useState('');
  const [tt, setTt] = useState('');
  const [fSt, setFSt] = useState(null);
  const [tSt, setTSt] = useState(null);
  const [depArr, setDepArr] = useState('dep');
  const [date, setDate] = useState(now.toISOString().slice(0,10));
  const [time, setTime] = useState(now.toTimeString().slice(0,5));
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState(null);
  const [isDB, setIsDB] = useState(true);

  const search = async () => {
    if (!fSt || !tSt) { Alert.alert('Fehler', 'Bitte Start und Ziel aus der Liste wählen.'); return; }
    Keyboard.dismiss();
    setLoading(true); setResults(null);
    const when = new Date(`${date}T${time}:00`).toISOString();
    const arriveBy = depArr === 'arr';

    if (dbOk && fSt._db && tSt._db) {
      try {
        const p = new URLSearchParams({ from: fSt.id, to: tSt.id, results: '8', stopovers: 'false', remarks: 'false', language: 'de' });
        p.set(arriveBy ? 'arrival' : 'departure', when);
        const r = await fetch(`${DB}/journeys?${p}`, { signal: AbortSignal.timeout(8000) });
        if (r.ok) {
          const d = await r.json();
          setResults(d.journeys || []); setIsDB(true);
          setLoading(false); return;
        }
      } catch { dbOk = false; }
    }
    try {
      const p = new URLSearchParams({ fromPlace: `${fSt.lat},${fSt.lon}`, toPlace: `${tSt.lat},${tSt.lon}`, time: when, arriveBy: String(arriveBy), numItineraries: '8' });
      const r = await fetch(`${PLAN}?${p}`);
      if (!r.ok) throw new Error(`Fehler ${r.status}`);
      const d = await r.json();
      setResults(d.itineraries || []); setIsDB(false);
    } catch (e) { Alert.alert('Fehler', e.message); }
    setLoading(false);
  };

  return (
    <ScrollView style={s.screen} contentContainerStyle={s.scroll} keyboardShouldPersistTaps="handled">
      <Text style={s.largeTitle}>Verbindungen</Text>

      <View style={s.card}>
        <StationInput placeholder="Von" value={ft} onChange={setFt}
          onSelect={x => { setFSt(x); setFt(x.name); }} dotColor={C.green} />
        <Sep />
        <View style={s.swapRow}>
          <View style={s.swapLine} />
          <TouchableOpacity style={s.swapBtn} onPress={() => {
            setFt(tt); setTt(ft); setFSt(tSt); setTSt(fSt);
          }}>
            <Text style={{ fontSize: 14, color: C.label2 }}>⇅</Text>
          </TouchableOpacity>
          <View style={s.swapLine} />
        </View>
        <StationInput placeholder="Nach" value={tt} onChange={setTt}
          onSelect={x => { setTSt(x); setTt(x.name); }} dotColor={C.brand} />
      </View>

      <View style={[s.card, { flexDirection: 'row', overflow: 'hidden', padding: 0 }]}>
        <TouchableOpacity style={s.timeSeg} onPress={() => setDepArr(d => d === 'dep' ? 'arr' : 'dep')}>
          <Text style={s.timeTxt}>{depArr === 'dep' ? 'Abfahrt' : 'Ankunft'}</Text>
        </TouchableOpacity>
        <View style={s.timeDivSep} />
        <TextInput style={s.timeSeg} value={date} onChangeText={setDate}
          placeholder="Datum" placeholderTextColor={C.label3}
          keyboardType="numbers-and-punctuation" />
        <View style={s.timeDivSep} />
        <TextInput style={s.timeSeg} value={time} onChangeText={setTime}
          placeholder="Zeit" placeholderTextColor={C.label3}
          keyboardType="numbers-and-punctuation" />
      </View>

      <TouchableOpacity style={[s.cta, loading && s.ctaDis]} onPress={search} disabled={loading} activeOpacity={0.8}>
        {loading
          ? <ActivityIndicator color="#fff" />
          : <Text style={s.ctaTxt}>Suchen</Text>}
      </TouchableOpacity>

      {results !== null && (
        <View style={{ marginTop: 20 }}>
          <Text style={s.secHd}>{results.length} Verbindungen{isDB ? ' · DB Echtzeit ●' : ''}</Text>
          {results.length === 0
            ? <View style={s.empty}><Text style={s.emptyIco}>🔍</Text><Text style={s.emptyTxt}>Keine Verbindungen</Text></View>
            : results.map((j, i) => <JCard key={i} j={j} fromName={fSt?.name || ''} toName={tSt?.name || ''} isDB={isDB} />)
          }
        </View>
      )}
    </ScrollView>
  );
}

/* ─── SCREEN: ABFAHRTEN ─── */
function DepScreen() {
  const [stTxt, setStTxt] = useState('');
  const [st, setSt] = useState(null);
  const [deps, setDeps] = useState(null);
  const [loading, setLoading] = useState(false);
  const [favs, setFavs] = useState([]);

  useEffect(() => {
    AsyncStorage.getItem('zugFavs').then(v => { if (v) setFavs(JSON.parse(v)); });
  }, []);

  const saveFavs = f => { setFavs(f); AsyncStorage.setItem('zugFavs', JSON.stringify(f)); };
  const isFav = id => favs.some(f => f.id === id);
  const toggleFav = () => {
    if (!st) return;
    let f = [...favs];
    if (isFav(st.id)) f = f.filter(x => x.id !== st.id);
    else f.unshift({ id: st.id, name: st.name, icon: st.icon || '🚉', _db: st._db, lat: st.lat, lon: st.lon, products: st.products, modes: st.modes });
    saveFavs(f);
  };

  const loadDep = async station => {
    setLoading(true); setDeps(null);
    if (dbOk && station._db) {
      try {
        const r = await fetch(`${DB}/stops/${encodeURIComponent(station.id)}/departures?results=25&duration=120`, { signal: AbortSignal.timeout(6000) });
        if (r.ok) { const d = await r.json(); setDeps({ data: d.departures || d, type: 'db' }); setLoading(false); return; }
      } catch { dbOk = false; }
    }
    try {
      const r = await fetch(`${DEPST}?stopId=${encodeURIComponent(station.id)}&n=25&time=${new Date().toISOString()}`);
      if (!r.ok) throw new Error();
      const d = await r.json();
      setDeps({ data: d.stopTimes || [], type: 't' });
    } catch (e) { Alert.alert('Fehler', 'Abfahrten konnten nicht geladen werden.'); }
    setLoading(false);
  };

  return (
    <ScrollView style={s.screen} contentContainerStyle={s.scroll} keyboardShouldPersistTaps="handled">
      <Text style={s.largeTitle}>Abfahrten</Text>
      <View style={s.card}>
        <StationInput placeholder="Bahnhof oder Haltestelle" value={stTxt} onChange={setStTxt}
          onSelect={x => { setSt(x); setStTxt(x.name); loadDep(x); }} dotColor={C.blue} />
      </View>
      {loading && <ActivityIndicator style={{ marginTop: 32 }} size="large" color={C.brand} />}
      {st && deps && (
        <View style={{ marginTop: 8 }}>
          <View style={s.depHdr}>
            <Text style={s.depTitle}>{st.name}</Text>
            <TouchableOpacity onPress={toggleFav}>
              <Text style={[s.star, isFav(st.id) && { color: C.orange }]}>{isFav(st.id) ? '★' : '☆'}</Text>
            </TouchableOpacity>
          </View>
          <View style={s.card}>
            {deps.data.length === 0
              ? <Text style={{ padding: 16, color: C.label2 }}>Keine Abfahrten</Text>
              : deps.data.map((dep, i) => {
                  if (deps.type === 'db') {
                    const col = lineCol(dep.line?.name);
                    const dR = dep.when || dep.plannedWhen;
                    const dd = delayMin(dep.plannedWhen, dR);
                    const pl = dep.platform || dep.plannedPlatform || '';
                    return (
                      <View key={i} style={[s.depRow, i > 0 && s.depSep]}>
                        <Pill label={dep.line?.name || '?'} color={col} />
                        <View style={s.depInfo}>
                          <Text style={s.depDest} numberOfLines={1}>{dep.direction || '?'}</Text>
                          {pl ? <Text style={s.depSub}>Gleis {pl}</Text> : null}
                        </View>
                        <View style={{ alignItems: 'flex-end' }}>
                          <Text style={s.depTime}>{fmtTime(dR)}</Text>
                          <Delay d={dd} />
                        </View>
                      </View>
                    );
                  } else {
                    const col = modeCol(dep.mode);
                    const n = dep.routeShortName || dep.displayName || '?';
                    const dR = dep.place?.departure;
                    const dd = dep.realTime ? delayMin(dep.place?.scheduledDeparture, dR) : 0;
                    const tr = dep.place?.track || '';
                    return (
                      <View key={i} style={[s.depRow, i > 0 && s.depSep]}>
                        <Pill label={n} color={col} />
                        <View style={s.depInfo}>
                          <Text style={s.depDest} numberOfLines={1}>{dep.headsign || '?'}</Text>
                          {tr ? <Text style={s.depSub}>Gleis {tr}</Text> : null}
                        </View>
                        <View style={{ alignItems: 'flex-end' }}>
                          <Text style={s.depTime}>{fmtTime(dR)}</Text>
                          {dep.realTime && <Delay d={dd} />}
                        </View>
                      </View>
                    );
                  }
                })
            }
          </View>
        </View>
      )}
    </ScrollView>
  );
}

/* ─── SCREEN: FAVORITEN ─── */
function FavScreen({ onOpenDep }) {
  const [favs, setFavs] = useState([]);
  useEffect(() => {
    const load = () => AsyncStorage.getItem('zugFavs').then(v => setFavs(v ? JSON.parse(v) : []));
    load();
    const t = setInterval(load, 2000);
    return () => clearInterval(t);
  }, []);
  const remove = id => {
    const f = favs.filter(x => x.id !== id);
    setFavs(f); AsyncStorage.setItem('zugFavs', JSON.stringify(f));
  };
  return (
    <ScrollView style={s.screen} contentContainerStyle={s.scroll}>
      <Text style={s.largeTitle}>Favoriten</Text>
      {favs.length === 0 ? (
        <View style={s.empty}>
          <Text style={s.emptyIco}>⭐</Text>
          <Text style={s.emptyTxt}>Keine Favoriten</Text>
          <Text style={s.emptySub}>Unter Abfahrten ★ tippen</Text>
        </View>
      ) : (
        <>
          <Text style={s.secHd}>Gespeicherte Bahnhöfe</Text>
          <View style={s.card}>
            {favs.map((f, i) => (
              <TouchableOpacity key={f.id} style={[s.favRow, i > 0 && s.depSep]} onPress={() => onOpenDep(f)} activeOpacity={0.7}>
                <View style={s.favIco}><Text style={{ fontSize: 20 }}>{f.icon || '🚉'}</Text></View>
                <View style={{ flex: 1 }}>
                  <Text style={s.favName}>{f.name}</Text>
                  <Text style={s.favSub}>Abfahrten ansehen →</Text>
                </View>
                <TouchableOpacity onPress={() => remove(f.id)} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
                  <Text style={{ fontSize: 18, color: C.label3, paddingLeft: 12 }}>✕</Text>
                </TouchableOpacity>
              </TouchableOpacity>
            ))}
          </View>
        </>
      )}
    </ScrollView>
  );
}

/* ─── TAB BAR ─── */
const TABS = [
  { key: 'search', label: 'Suchen',    icon: '🔍' },
  { key: 'dep',    label: 'Abfahrten', icon: '🕑' },
  { key: 'fav',    label: 'Favoriten', icon: '⭐' },
];

function TabBar({ active, onChange }) {
  return (
    <View style={s.tabBar}>
      {TABS.map(t => (
        <TouchableOpacity key={t.key} style={s.tabItem} onPress={() => onChange(t.key)} activeOpacity={0.7}>
          <Text style={[s.tabIco, active === t.key && { opacity: 1 }]}>{t.icon}</Text>
          <Text style={[s.tabLbl, active === t.key && { color: C.brand }]}>{t.label}</Text>
        </TouchableOpacity>
      ))}
    </View>
  );
}

/* ─── ROOT APP ─── */
export default function App() {
  const [tab, setTab] = useState('search');

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="dark-content" />
      <View style={{ flex: 1 }}>
        {tab === 'search' && <SearchScreen />}
        {tab === 'dep' && <DepScreen />}
        {tab === 'fav' && <FavScreen onOpenDep={st => { setTab('dep'); }} />}
      </View>
      <TabBar active={tab} onChange={setTab} />
    </SafeAreaView>
  );
}

/* ─── STYLES ─── */
const shadow = Platform.select({
  ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.06, shadowRadius: 4 },
  android: { elevation: 2 },
});

const s = StyleSheet.create({
  screen: { flex: 1, backgroundColor: C.bg },
  scroll: { padding: 16, paddingBottom: 24 },
  largeTitle: { fontSize: 34, fontWeight: '700', letterSpacing: 0.37, marginBottom: 20, marginTop: 4 },
  card: { backgroundColor: C.card, borderRadius: 10, marginBottom: 10, ...shadow },
  sep: { height: 0.5, backgroundColor: C.sep, marginLeft: 16 },
  secHd: { fontSize: 13, color: C.label2, textTransform: 'uppercase', letterSpacing: 0.4, marginBottom: 8, paddingLeft: 4 },

  inputRow: { flexDirection: 'row', alignItems: 'center', padding: 13, paddingLeft: 16, minHeight: 44, gap: 12 },
  inputDot: { width: 9, height: 9, borderRadius: 5 },
  input: { flex: 1, fontSize: 17, color: C.label },

  sugBox: {
    position: 'absolute', top: '100%', left: 0, right: 0, zIndex: 999,
    backgroundColor: C.card, borderRadius: 10, overflow: 'hidden',
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.14, shadowRadius: 12 },
      android: { elevation: 8 },
    }),
  },
  sugRow: { flexDirection: 'row', alignItems: 'center', padding: 12, paddingLeft: 16, gap: 12, minHeight: 44 },
  sugSep: { borderTopWidth: 0.5, borderTopColor: C.sep },
  sugIco: { fontSize: 20 },
  sugName: { fontSize: 16, color: C.label, flex: 1 },

  swapRow: { flexDirection: 'row', alignItems: 'center', marginLeft: 16, height: 26 },
  swapLine: { flex: 1, height: 0.5, backgroundColor: C.sep },
  swapBtn: { width: 26, height: 26, borderRadius: 13, backgroundColor: C.fill, alignItems: 'center', justifyContent: 'center' },

  timeSeg: { flex: 1, padding: 13, fontSize: 14, fontWeight: '500', color: C.label, textAlign: 'center' },
  timeTxt: { fontSize: 14, fontWeight: '500', color: C.label, textAlign: 'center' },
  timeDivSep: { width: 0.5, backgroundColor: C.sep },

  cta: {
    backgroundColor: C.brand, borderRadius: 10, padding: 14, alignItems: 'center', marginBottom: 8,
    ...Platform.select({
      ios: { shadowColor: C.brand, shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 8 },
      android: { elevation: 4 },
    }),
  },
  ctaDis: { opacity: 0.5 },
  ctaTxt: { color: '#fff', fontSize: 17, fontWeight: '600' },

  jCard: { backgroundColor: C.card, borderRadius: 10, marginBottom: 8, overflow: 'hidden', ...shadow },
  jTop: { flexDirection: 'row', padding: 14, alignItems: 'center' },
  jCol: { flex: 1 },
  jTime: { fontSize: 22, fontWeight: '700', letterSpacing: -0.5 },
  delay: { fontSize: 11, fontWeight: '600', marginTop: 2 },
  jSt: { fontSize: 11, color: C.label2, marginTop: 4 },
  jMid: { alignItems: 'center', paddingHorizontal: 8 },
  jDur: { fontSize: 12, color: C.label2, fontWeight: '500' },
  jBar: { width: 56, height: 2, backgroundColor: '#D1D1D6', borderRadius: 2, marginVertical: 5, position: 'relative' },
  jDot: { position: 'absolute', width: 6, height: 6, borderRadius: 3, top: -2 },
  jChg: { fontSize: 11, color: C.label2 },
  jPills: { flexDirection: 'row', flexWrap: 'wrap', gap: 4, paddingHorizontal: 14, paddingBottom: 10 },
  jChevRow: { alignItems: 'center', padding: 8 },
  jChevTxt: { fontSize: 12, color: C.label3, fontWeight: '500' },
  pill: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 5 },
  pillTxt: { color: '#fff', fontSize: 12, fontWeight: '700' },

  detailBox: { backgroundColor: C.bg, padding: 14, borderTopWidth: 0.5, borderTopColor: C.sep },
  legRow: { flexDirection: 'row' },
  legTL: { width: 28, alignItems: 'center', flexShrink: 0, paddingTop: 4 },
  legDot: { width: 10, height: 10, borderRadius: 5, borderWidth: 2, borderColor: C.bg },
  legLine: { width: 2, borderRadius: 2, flex: 1, minHeight: 20, marginVertical: 2 },
  legBody: { flex: 1, paddingBottom: 14 },
  legTR: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  legTime: { fontSize: 15, fontWeight: '700' },
  legSt: { fontSize: 14, fontWeight: '600', marginTop: 2 },
  plat: { fontSize: 11, color: C.label2, backgroundColor: '#E5E5EA', borderRadius: 5, paddingHorizontal: 7, paddingVertical: 1, alignSelf: 'flex-start', marginTop: 3, fontWeight: '600', overflow: 'hidden' },
  legLR: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingVertical: 8 },
  legDir: { fontSize: 13, color: C.label2, flex: 1 },
  walkTxt: { fontSize: 13, color: C.label2, flex: 1, paddingVertical: 8 },

  depHdr: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 4, marginBottom: 8 },
  depTitle: { fontSize: 20, fontWeight: '700' },
  star: { fontSize: 26, color: '#C7C7CC' },
  depRow: { flexDirection: 'row', alignItems: 'center', padding: 12, paddingHorizontal: 16, gap: 12, minHeight: 52 },
  depSep: { borderTopWidth: 0.5, borderTopColor: C.sep },
  depInfo: { flex: 1, minWidth: 0 },
  depDest: { fontSize: 15, fontWeight: '500' },
  depSub: { fontSize: 12, color: C.label2, marginTop: 2 },
  depTime: { fontSize: 17, fontWeight: '700', letterSpacing: -0.3 },

  favRow: { flexDirection: 'row', alignItems: 'center', padding: 12, paddingHorizontal: 16, minHeight: 52 },
  favIco: { width: 36, height: 36, borderRadius: 9, backgroundColor: 'rgba(236,0,22,.1)', alignItems: 'center', justifyContent: 'center', marginRight: 12 },
  favName: { fontSize: 16, fontWeight: '500' },
  favSub: { fontSize: 13, color: C.label2, marginTop: 1 },

  empty: { alignItems: 'center', paddingVertical: 48 },
  emptyIco: { fontSize: 52, marginBottom: 12 },
  emptyTxt: { fontSize: 15, color: C.label2 },
  emptySub: { fontSize: 13, color: C.label3, marginTop: 6, textAlign: 'center' },

  tabBar: {
    flexDirection: 'row',
    backgroundColor: 'rgba(249,249,249,0.97)',
    borderTopWidth: 0.5, borderTopColor: C.sep,
    paddingBottom: Platform.OS === 'ios' ? 20 : 4,
  },
  tabItem: { flex: 1, alignItems: 'center', paddingTop: 8, paddingBottom: 4 },
  tabIco: { fontSize: 24, opacity: 0.4 },
  tabLbl: { fontSize: 10, fontWeight: '500', color: C.label3, marginTop: 2 },
});
