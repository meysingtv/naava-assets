import React, { useState, useRef, useCallback } from 'react';
import {
  View, Text, TextInput, TouchableOpacity, FlatList,
  StyleSheet, Platform, SafeAreaView, StatusBar,
  ActivityIndicator, ScrollView, Animated, Alert,
  Pressable, Keyboard,
} from 'react-native';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import AsyncStorage from '@react-native-async-storage/async-storage';

/* ─────────────────────────────────────────────
   KONSTANTEN & API
───────────────────────────────────────────── */
const DB    = 'https://v6.db.transport.rest';
const GEO   = 'https://api.transitous.org/api/v1/geocode';
const PLAN  = 'https://api.transitous.org/api/v3/plan';
const STOPS = 'https://api.transitous.org/api/v1/stoptimes';

/* iOS System Colors */
const C = {
  bg:      '#F2F2F7',
  card:    '#FFFFFF',
  label:   '#000000',
  label2:  'rgba(60,60,67,0.6)',
  label3:  'rgba(60,60,67,0.3)',
  sep:     'rgba(60,60,67,0.12)',
  fill:    'rgba(120,120,128,0.12)',
  blue:    '#007AFF',
  red:     '#FF3B30',
  green:   '#34C759',
  orange:  '#FF9500',
  brand:   '#EC0016',
};

/* ─────────────────────────────────────────────
   HILFSFUNKTIONEN
───────────────────────────────────────────── */
function fmtTime(iso) {
  if (!iso) return '--:--';
  return new Date(iso).toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
}
function fmtDur(secs) {
  if (!secs || secs < 0) return '?';
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  return h > 0 ? `${h}h ${m}min` : `${m} min`;
}
function delayMin(planned, actual) {
  if (!planned || !actual) return 0;
  return Math.round((new Date(actual) - new Date(planned)) / 60000);
}

function lineColor(name) {
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
}
function modeColor(mode) {
  switch ((mode || '').toUpperCase()) {
    case 'HIGHSPEED_RAIL': return '#EC0016';
    case 'LONG_DISTANCE':  return '#C4000F';
    case 'REGIONAL_FAST_RAIL':
    case 'REGIONAL_RAIL':
    case 'RAIL':           return '#0066CC';
    case 'SUBURBAN':
    case 'METRO':
    case 'SUBWAY':         return '#007E3C';
    case 'TRAM':           return '#C0003C';
    case 'BUS':
    case 'COACH':          return '#7C3AED';
    case 'FERRY':          return '#0891B2';
    default:               return '#8E8E93';
  }
}
function stationIcon(products, modes) {
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
}

/* ─────────────────────────────────────────────
   GEMEINSAME KOMPONENTEN
───────────────────────────────────────────── */
function Pill({ label, color }) {
  return (
    <View style={[styles.pill, { backgroundColor: color }]}>
      <Text style={styles.pillText}>{label}</Text>
    </View>
  );
}

function DelayBadge({ delay }) {
  if (delay <= 0) return <Text style={[styles.delay, { color: C.green }]}>pünktlich</Text>;
  return <Text style={[styles.delay, { color: C.red }]}>+{delay} min</Text>;
}

function SectionHeader({ title }) {
  return <Text style={styles.sectionHeader}>{title}</Text>;
}

function Separator() {
  return <View style={styles.sep} />;
}

/* ─────────────────────────────────────────────
   AUTOCOMPLETE
───────────────────────────────────────────── */
let dbAvailable = true;

function StationInput({ placeholder, value, onChange, onSelect, dotColor }) {
  const [suggestions, setSuggestions] = useState([]);
  const [loading, setLoading] = useState(false);
  const timer = useRef(null);

  const fetch_ = useCallback(async (q) => {
    if (q.length < 2) { setSuggestions([]); return; }
    setLoading(true);
    try {
      // DB HAFAS versuchen
      if (dbAvailable) {
        try {
          const r = await fetch(
            `${DB}/locations?query=${encodeURIComponent(q)}&results=10&stops=true&addresses=false&poi=false`,
            { signal: AbortSignal.timeout(5000) }
          );
          if (r.ok) {
            const data = await r.json();
            const mapped = (data || []).map(s => ({
              id: s.id, name: s.name,
              lat: s.location?.latitude, lon: s.location?.longitude,
              products: s.products, _db: true,
              icon: stationIcon(s.products, null),
            }));
            setSuggestions(mapped);
            setLoading(false); return;
          }
        } catch { dbAvailable = false; }
      }
      // Fallback Transitous
      const r = await fetch(`${GEO}?text=${encodeURIComponent(q)}&language=de`);
      const data = await r.json();
      const RAIL = ['HIGHSPEED_RAIL','LONG_DISTANCE','REGIONAL_RAIL','REGIONAL_FAST_RAIL','SUBURBAN','RAIL'];
      const stops = (data || []).filter(s => s.type === 'STOP');
      stops.sort((a, b) => {
        const aR = (a.modes||[]).some(m => RAIL.includes(m));
        const bR = (b.modes||[]).some(m => RAIL.includes(m));
        if (aR && !bR) return -1; if (!aR && bR) return 1;
        return (b.importance||0) - (a.importance||0);
      });
      setSuggestions(stops.slice(0, 10).map(s => ({
        id: s.id, name: s.name, lat: s.lat, lon: s.lon,
        modes: s.modes, _db: false,
        icon: stationIcon(null, s.modes),
      })));
    } catch (e) {
      setSuggestions([]);
    }
    setLoading(false);
  }, []);

  const onChangeText = (text) => {
    onChange(text);
    clearTimeout(timer.current);
    timer.current = setTimeout(() => fetch_(text.trim()), 220);
  };

  const onPickStation = (s) => {
    onChange(s.name);
    onSelect(s);
    setSuggestions([]);
    Keyboard.dismiss();
  };

  return (
    <View>
      <View style={styles.inputRow}>
        <View style={[styles.inputDot, { backgroundColor: dotColor }]} />
        <TextInput
          style={styles.textInput}
          placeholder={placeholder}
          placeholderTextColor={C.label3}
          value={value}
          onChangeText={onChangeText}
          autoCorrect={false}
          autoCapitalize="words"
          returnKeyType="search"
        />
        {loading && <ActivityIndicator size="small" color={C.brand} />}
      </View>
      {suggestions.length > 0 && (
        <View style={styles.sugContainer}>
          {suggestions.map((s, i) => (
            <TouchableOpacity
              key={s.id + i}
              style={[styles.sugRow, i > 0 && styles.sugSep]}
              onPress={() => onPickStation(s)}
              activeOpacity={0.6}
            >
              <Text style={styles.sugIcon}>{s.icon}</Text>
              <Text style={styles.sugName} numberOfLines={1}>{s.name}</Text>
            </TouchableOpacity>
          ))}
        </View>
      )}
    </View>
  );
}

/* ─────────────────────────────────────────────
   VERBINDUNGS-DETAIL
───────────────────────────────────────────── */
function JourneyDetail({ legs, isDB }) {
  if (!legs) return null;
  return (
    <View style={styles.detailWrap}>
      {legs.map((leg, i) => {
        const isLast = i === legs.length - 1;
        if (isDB) {
          if (leg.walking) {
            const mins = Math.ceil((new Date(leg.arrival) - new Date(leg.departure)) / 60000);
            return (
              <View key={i} style={styles.legRow}>
                <View style={styles.legTimeline}>
                  <View style={[styles.legDot, { backgroundColor: C.label3 }]} />
                  <View style={[styles.legLine, { backgroundColor: C.fill }]} />
                </View>
                <Text style={styles.walkText}>🚶 {mins || 1} min Fußweg</Text>
              </View>
            );
          }
          const col = lineColor(leg.line?.name);
          const dR = leg.departure || leg.plannedDeparture;
          const dS = leg.plannedDeparture;
          const aR = leg.arrival || leg.plannedArrival;
          const aS = leg.plannedArrival;
          const dd = delayMin(dS, dR);
          const da = delayMin(aS, aR);
          const oP = leg.departurePlatform || leg.plannedDeparturePlatform || '';
          const dP = leg.arrivalPlatform || leg.plannedArrivalPlatform || '';
          return (
            <View key={i}>
              <View style={styles.legRow}>
                <View style={styles.legTimeline}>
                  <View style={[styles.legDot, { backgroundColor: C.green }]} />
                  <View style={[styles.legLine, { backgroundColor: col }]} />
                </View>
                <View style={styles.legBody}>
                  <View style={styles.legTimeRow}>
                    <Text style={styles.legTime}>{fmtTime(dR)}</Text>
                    <DelayBadge delay={dd} />
                  </View>
                  <Text style={styles.legStation}>{leg.origin?.name}</Text>
                  {oP ? <Text style={styles.legPlatform}>Gleis {oP}</Text> : null}
                  <View style={styles.legLineRow}>
                    <Pill label={leg.line?.name || '?'} color={col} />
                    <Text style={styles.legDir} numberOfLines={1}>
                      Richtung {leg.direction || leg.destination?.name}
                    </Text>
                  </View>
                </View>
              </View>
              {isLast && (
                <View style={styles.legRow}>
                  <View style={styles.legTimeline}>
                    <View style={[styles.legDot, { backgroundColor: C.brand }]} />
                  </View>
                  <View style={styles.legBody}>
                    <View style={styles.legTimeRow}>
                      <Text style={styles.legTime}>{fmtTime(aR)}</Text>
                      <DelayBadge delay={da} />
                    </View>
                    <Text style={styles.legStation}>{leg.destination?.name}</Text>
                    {dP ? <Text style={styles.legPlatform}>Gleis {dP}</Text> : null}
                  </View>
                </View>
              )}
            </View>
          );
        } else {
          // Transitous format
          if (leg.mode === 'WALK') {
            const mins = Math.round((leg.duration || 0) / 60);
            return (
              <View key={i} style={styles.legRow}>
                <View style={styles.legTimeline}>
                  <View style={[styles.legDot, { backgroundColor: C.label3 }]} />
                  <View style={[styles.legLine, { backgroundColor: C.fill }]} />
                </View>
                <Text style={styles.walkText}>🚶 {mins || 1} min Fußweg</Text>
              </View>
            );
          }
          const col = modeColor(leg.mode);
          const n = leg.routeShortName || leg.displayName || '?';
          const dR = leg.from?.departure || leg.startTime;
          const dS = leg.from?.scheduledDeparture || leg.scheduledStartTime;
          const aR = leg.to?.arrival || leg.endTime;
          const aS = leg.to?.scheduledArrival || leg.scheduledEndTime;
          const dd = leg.realTime ? delayMin(dS, dR) : 0;
          const da = leg.realTime ? delayMin(aS, aR) : 0;
          const oT = leg.from?.track || leg.from?.scheduledTrack || '';
          const dT = leg.to?.track || leg.to?.scheduledTrack || '';
          return (
            <View key={i}>
              <View style={styles.legRow}>
                <View style={styles.legTimeline}>
                  <View style={[styles.legDot, { backgroundColor: C.green }]} />
                  <View style={[styles.legLine, { backgroundColor: col }]} />
                </View>
                <View style={styles.legBody}>
                  <View style={styles.legTimeRow}>
                    <Text style={styles.legTime}>{fmtTime(dR)}</Text>
                    {leg.realTime && <DelayBadge delay={dd} />}
                  </View>
                  <Text style={styles.legStation}>{leg.from?.name}</Text>
                  {oT ? <Text style={styles.legPlatform}>Gleis {oT}</Text> : null}
                  <View style={styles.legLineRow}>
                    <Pill label={n} color={col} />
                    <Text style={styles.legDir} numberOfLines={1}>
                      Richtung {leg.headsign || leg.to?.name}
                    </Text>
                  </View>
                </View>
              </View>
              {isLast && (
                <View style={styles.legRow}>
                  <View style={styles.legTimeline}>
                    <View style={[styles.legDot, { backgroundColor: C.brand }]} />
                  </View>
                  <View style={styles.legBody}>
                    <View style={styles.legTimeRow}>
                      <Text style={styles.legTime}>{fmtTime(aR)}</Text>
                      {leg.realTime && <DelayBadge delay={da} />}
                    </View>
                    <Text style={styles.legStation}>{leg.to?.name}</Text>
                    {dT ? <Text style={styles.legPlatform}>Gleis {dT}</Text> : null}
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

/* ─────────────────────────────────────────────
   VERBINDUNGS-KARTE
───────────────────────────────────────────── */
function JourneyCard({ journey, index, fromName, toName, isDB }) {
  const [open, setOpen] = useState(false);

  let depR, depS, arrR, arrS, pills, legs, changes, duration;

  if (isDB) {
    legs = journey.legs || [];
    const transit = legs.filter(l => !l.walking);
    if (!transit.length) return null;
    const f = transit[0], la = transit[transit.length - 1];
    depR = f.departure || f.plannedDeparture;
    depS = f.plannedDeparture;
    arrR = la.arrival || la.plannedArrival;
    arrS = la.plannedArrival;
    changes = transit.length - 1;
    duration = (new Date(arrR) - new Date(depR)) / 1000;
    pills = transit.map((l, i) => (
      <Pill key={i} label={l.line?.name || '?'} color={lineColor(l.line?.name)} />
    ));
  } else {
    legs = journey.legs || [];
    const SKIP = ['HIGHSPEED_RAIL','LONG_DISTANCE','NIGHT_RAIL','COACH'];
    const transit = legs.filter(l => l.mode !== 'WALK');
    if (!transit.length || transit.some(l => SKIP.includes(l.mode))) return null;
    const f = transit[0], la = transit[transit.length - 1];
    depR = f.from?.departure || f.startTime;
    depS = f.from?.scheduledDeparture || f.scheduledStartTime;
    arrR = la.to?.arrival || la.endTime;
    arrS = la.to?.scheduledArrival || la.scheduledEndTime;
    changes = journey.transfers ?? Math.max(0, transit.length - 1);
    duration = journey.duration;
    pills = transit.map((l, i) => (
      <Pill key={i} label={l.routeShortName || l.displayName || '?'} color={modeColor(l.mode)} />
    ));
  }

  const dDep = delayMin(depS, depR);
  const dArr = delayMin(arrS, arrR);

  return (
    <View style={styles.jCard}>
      <TouchableOpacity onPress={() => setOpen(o => !o)} activeOpacity={0.7}>
        <View style={styles.jTop}>
          {/* Abfahrt */}
          <View style={styles.jTimeCol}>
            <Text style={styles.jTimeBig}>{fmtTime(depR)}</Text>
            <DelayBadge delay={dDep} />
            <Text style={styles.jStation} numberOfLines={1}>{fromName}</Text>
          </View>
          {/* Mitte */}
          <View style={styles.jMid}>
            <Text style={styles.jDur}>{fmtDur(duration)}</Text>
            <View style={styles.jBar}>
              <View style={[styles.jBarDot, { backgroundColor: C.green, left: -3 }]} />
              <View style={[styles.jBarDot, { backgroundColor: C.brand, right: -3 }]} />
            </View>
            <Text style={styles.jChg}>
              {changes === 0 ? 'Direkt' : `${changes} Umst.`}
            </Text>
          </View>
          {/* Ankunft */}
          <View style={[styles.jTimeCol, styles.jTimeRight]}>
            <Text style={[styles.jTimeBig, { textAlign: 'right' }]}>{fmtTime(arrR)}</Text>
            <DelayBadge delay={dArr} />
            <Text style={[styles.jStation, { textAlign: 'right' }]} numberOfLines={1}>{toName}</Text>
          </View>
        </View>
        {/* Linien */}
        <View style={styles.jPills}>{pills}</View>
        <Separator />
        <View style={styles.jChevRow}>
          <Text style={styles.jChevText}>Details</Text>
          <Text style={styles.jChevIcon}>{open ? '▲' : '▼'}</Text>
        </View>
      </TouchableOpacity>
      {open && <JourneyDetail legs={legs} isDB={isDB} />}
    </View>
  );
}

/* ─────────────────────────────────────────────
   SCREEN 1: VERBINDUNGEN SUCHEN
───────────────────────────────────────────── */
function SearchScreen() {
  const now = new Date();
  const [fromText, setFromText] = useState('');
  const [toText, setToText] = useState('');
  const [fromSt, setFromSt] = useState(null);
  const [toSt, setToSt] = useState(null);
  const [depArr, setDepArr] = useState('dep');
  const [date, setDate] = useState(now.toISOString().slice(0,10));
  const [time, setTime] = useState(now.toTimeString().slice(0,5));
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState(null);
  const [isDB, setIsDB] = useState(true);

  const swap = () => {
    setFromText(toText); setToText(fromText);
    setFromSt(toSt); setToSt(fromSt);
  };

  const search = async () => {
    if (!fromSt || !toSt) {
      Alert.alert('Fehler', 'Bitte Start und Ziel aus der Liste auswählen.');
      return;
    }
    Keyboard.dismiss();
    setLoading(true);
    setResults(null);
    const when = new Date(`${date}T${time}:00`).toISOString();
    const arriveBy = depArr === 'arr';

    if (dbAvailable && fromSt._db && toSt._db) {
      try {
        const p = new URLSearchParams({ from: fromSt.id, to: toSt.id, results: '8', stopovers: 'false', remarks: 'false', language: 'de' });
        p.set(arriveBy ? 'arrival' : 'departure', when);
        const r = await fetch(`${DB}/journeys?${p}`, { signal: AbortSignal.timeout(8000) });
        if (r.ok) {
          const d = await r.json();
          setResults(d.journeys || []); setIsDB(true);
          setLoading(false); return;
        }
      } catch { dbAvailable = false; }
    }

    try {
      const p = new URLSearchParams({ fromPlace: `${fromSt.lat},${fromSt.lon}`, toPlace: `${toSt.lat},${toSt.lon}`, time: when, arriveBy: String(arriveBy), numItineraries: '8' });
      const r = await fetch(`${PLAN}?${p}`);
      if (!r.ok) throw new Error(`Fehler ${r.status}`);
      const d = await r.json();
      setResults(d.itineraries || []); setIsDB(false);
    } catch (e) {
      Alert.alert('Fehler', e.message);
    }
    setLoading(false);
  };

  return (
    <SafeAreaView style={styles.screen}>
      <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.scrollContent}>
        <Text style={styles.largeTitle}>Verbindungen</Text>

        {/* Suche */}
        <View style={styles.card}>
          <StationInput
            placeholder="Von"
            value={fromText}
            onChange={setFromText}
            onSelect={st => { setFromSt(st); setFromText(st.name); }}
            dotColor={C.green}
          />
          <Separator />
          <View style={styles.swapRow}>
            <View style={styles.swapLine} />
            <TouchableOpacity style={styles.swapBtn} onPress={swap}>
              <Text style={styles.swapIcon}>⇅</Text>
            </TouchableOpacity>
          </View>
          <StationInput
            placeholder="Nach"
            value={toText}
            onChange={setToText}
            onSelect={st => { setToSt(st); setToText(st.name); }}
            dotColor={C.brand}
          />
        </View>

        {/* Zeit */}
        <View style={[styles.card, styles.timeCard]}>
          <TouchableOpacity
            style={styles.timePill}
            onPress={() => setDepArr(d => d === 'dep' ? 'arr' : 'dep')}
          >
            <Text style={styles.timePillText}>{depArr === 'dep' ? 'Abfahrt' : 'Ankunft'}</Text>
          </TouchableOpacity>
          <View style={styles.timeSep} />
          <TextInput
            style={styles.timePill}
            value={date}
            onChangeText={setDate}
            placeholder="YYYY-MM-DD"
            placeholderTextColor={C.label3}
            keyboardType="numbers-and-punctuation"
          />
          <View style={styles.timeSep} />
          <TextInput
            style={styles.timePill}
            value={time}
            onChangeText={setTime}
            placeholder="HH:MM"
            placeholderTextColor={C.label3}
            keyboardType="numbers-and-punctuation"
          />
        </View>

        <TouchableOpacity
          style={[styles.ctaBtn, loading && styles.ctaDisabled]}
          onPress={search}
          disabled={loading}
          activeOpacity={0.8}
        >
          {loading
            ? <ActivityIndicator color="#fff" />
            : <Text style={styles.ctaText}>Suchen</Text>
          }
        </TouchableOpacity>

        {/* Ergebnisse */}
        {results !== null && (
          <View style={{ marginTop: 20 }}>
            <SectionHeader title={`${results.length} Verbindungen${isDB ? ' · DB Echtzeit' : ''}`} />
            {results.length === 0 ? (
              <View style={styles.empty}>
                <Text style={styles.emptyIcon}>🔍</Text>
                <Text style={styles.emptyText}>Keine Verbindungen gefunden</Text>
              </View>
            ) : (
              results.map((j, i) => (
                <JourneyCard
                  key={i} journey={j} index={i}
                  fromName={fromSt?.name || ''} toName={toSt?.name || ''}
                  isDB={isDB}
                />
              ))
            )}
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

/* ─────────────────────────────────────────────
   SCREEN 2: ABFAHRTEN
───────────────────────────────────────────── */
function DeparturesScreen() {
  const [stText, setStText] = useState('');
  const [station, setStation] = useState(null);
  const [departures, setDepartures] = useState(null);
  const [loading, setLoading] = useState(false);
  const [favs, setFavs] = useState([]);

  React.useEffect(() => {
    AsyncStorage.getItem('zugFavs').then(v => { if (v) setFavs(JSON.parse(v)); });
  }, []);

  const saveFavs = (f) => { setFavs(f); AsyncStorage.setItem('zugFavs', JSON.stringify(f)); };
  const isFav = (id) => favs.some(f => f.id === id);
  const toggleFav = () => {
    if (!station) return;
    let f = [...favs];
    if (isFav(station.id)) f = f.filter(x => x.id !== station.id);
    else f.unshift({ id: station.id, name: station.name, icon: station.icon || '🚉', _db: station._db, lat: station.lat, lon: station.lon, products: station.products, modes: station.modes });
    saveFavs(f);
  };

  const loadDep = async (st) => {
    setLoading(true); setDepartures(null);
    if (dbAvailable && st._db) {
      try {
        const r = await fetch(`${DB}/stops/${encodeURIComponent(st.id)}/departures?results=25&duration=120`, { signal: AbortSignal.timeout(6000) });
        if (r.ok) { const d = await r.json(); setDepartures({ data: d.departures || d, type: 'db' }); setLoading(false); return; }
      } catch { dbAvailable = false; }
    }
    try {
      const r = await fetch(`${STOPS}?stopId=${encodeURIComponent(st.id)}&n=25&time=${new Date().toISOString()}`);
      if (!r.ok) throw new Error(`Fehler ${r.status}`);
      const d = await r.json();
      setDepartures({ data: d.stopTimes || [], type: 'transitous' });
    } catch (e) { Alert.alert('Fehler', e.message); }
    setLoading(false);
  };

  const onSelectStation = (st) => { setStation(st); setStText(st.name); loadDep(st); };

  return (
    <SafeAreaView style={styles.screen}>
      <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={styles.scrollContent}>
        <Text style={styles.largeTitle}>Abfahrten</Text>

        <View style={styles.card}>
          <StationInput
            placeholder="Bahnhof oder Haltestelle"
            value={stText}
            onChange={setStText}
            onSelect={onSelectStation}
            dotColor={C.blue}
          />
        </View>

        {loading && <ActivityIndicator style={{ marginTop: 32 }} size="large" color={C.brand} />}

        {station && departures && (
          <View style={{ marginTop: 20 }}>
            <View style={styles.depHeader}>
              <Text style={styles.depTitle}>{station.name}</Text>
              <TouchableOpacity onPress={toggleFav}>
                <Text style={[styles.starBtn, isFav(station.id) && { color: C.orange }]}>
                  {isFav(station.id) ? '★' : '☆'}
                </Text>
              </TouchableOpacity>
            </View>
            <View style={styles.card}>
              {departures.data.length === 0 ? (
                <Text style={[styles.emptyText, { padding: 16 }]}>Keine Abfahrten</Text>
              ) : departures.data.map((dep, i) => {
                if (departures.type === 'db') {
                  const col = lineColor(dep.line?.name);
                  const dR = dep.when || dep.plannedWhen;
                  const dS = dep.plannedWhen;
                  const dd = delayMin(dS, dR);
                  const pl = dep.platform || dep.plannedPlatform || '';
                  return (
                    <View key={i} style={[styles.depRow, i > 0 && styles.depSep]}>
                      <Pill label={dep.line?.name || '?'} color={col} />
                      <View style={styles.depInfo}>
                        <Text style={styles.depDest} numberOfLines={1}>{dep.direction || '?'}</Text>
                        {pl ? <Text style={styles.depPlat}>Gleis {pl}</Text> : null}
                      </View>
                      <View style={styles.depRight}>
                        <Text style={styles.depTime}>{fmtTime(dR)}</Text>
                        <DelayBadge delay={dd} />
                      </View>
                    </View>
                  );
                } else {
                  const col = modeColor(dep.mode);
                  const n = dep.routeShortName || dep.displayName || '?';
                  const dR = dep.place?.departure;
                  const dS = dep.place?.scheduledDeparture;
                  const dd = dep.realTime ? delayMin(dS, dR) : 0;
                  const tr = dep.place?.track || dep.place?.scheduledTrack || '';
                  return (
                    <View key={i} style={[styles.depRow, i > 0 && styles.depSep]}>
                      <Pill label={n} color={col} />
                      <View style={styles.depInfo}>
                        <Text style={styles.depDest} numberOfLines={1}>{dep.headsign || '?'}</Text>
                        {tr ? <Text style={styles.depPlat}>Gleis {tr}</Text> : null}
                      </View>
                      <View style={styles.depRight}>
                        <Text style={styles.depTime}>{fmtTime(dR)}</Text>
                        {dep.realTime && <DelayBadge delay={dd} />}
                      </View>
                    </View>
                  );
                }
              })}
            </View>
          </View>
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

/* ─────────────────────────────────────────────
   SCREEN 3: FAVORITEN
───────────────────────────────────────────── */
function FavoritesScreen({ navigation }) {
  const [favs, setFavs] = useState([]);

  React.useEffect(() => {
    const unsub = navigation.addListener('focus', () => {
      AsyncStorage.getItem('zugFavs').then(v => { if (v) setFavs(JSON.parse(v)); else setFavs([]); });
    });
    return unsub;
  }, [navigation]);

  const remove = (id) => {
    const f = favs.filter(x => x.id !== id);
    setFavs(f); AsyncStorage.setItem('zugFavs', JSON.stringify(f));
  };

  if (favs.length === 0) return (
    <SafeAreaView style={styles.screen}>
      <View style={styles.scrollContent}>
        <Text style={styles.largeTitle}>Favoriten</Text>
        <View style={styles.empty}>
          <Text style={styles.emptyIcon}>⭐</Text>
          <Text style={styles.emptyText}>Noch keine Favoriten</Text>
          <Text style={styles.emptySubText}>Unter Abfahrten ★ tippen um Bahnhöfe zu speichern</Text>
        </View>
      </View>
    </SafeAreaView>
  );

  return (
    <SafeAreaView style={styles.screen}>
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Text style={styles.largeTitle}>Favoriten</Text>
        <SectionHeader title="Gespeicherte Bahnhöfe" />
        <View style={styles.card}>
          {favs.map((f, i) => (
            <View key={f.id} style={[styles.favRow, i > 0 && { borderTopWidth: 0.5, borderTopColor: C.sep }]}>
              <View style={styles.favIcon}>
                <Text style={{ fontSize: 20 }}>{f.icon || '🚉'}</Text>
              </View>
              <View style={styles.favBody}>
                <Text style={styles.favName}>{f.name}</Text>
                <Text style={styles.favSub}>Abfahrten ansehen</Text>
              </View>
              <TouchableOpacity onPress={() => remove(f.id)}>
                <Text style={styles.favDel}>✕</Text>
              </TouchableOpacity>
            </View>
          ))}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

/* ─────────────────────────────────────────────
   APP NAVIGATION
───────────────────────────────────────────── */
const Tab = createBottomTabNavigator();

export default function App() {
  return (
    <NavigationContainer>
      <StatusBar barStyle="dark-content" />
      <Tab.Navigator
        screenOptions={{
          headerShown: false,
          tabBarActiveTintColor: C.brand,
          tabBarInactiveTintColor: C.label3,
          tabBarStyle: {
            backgroundColor: 'rgba(249,249,249,0.95)',
            borderTopColor: C.sep,
            borderTopWidth: 0.5,
          },
          tabBarLabelStyle: { fontSize: 10, fontWeight: '500' },
        }}
      >
        <Tab.Screen
          name="Suchen"
          component={SearchScreen}
          options={{ tabBarIcon: ({ color }) => <Text style={{ fontSize: 22 }}>🔍</Text> }}
        />
        <Tab.Screen
          name="Abfahrten"
          component={DeparturesScreen}
          options={{ tabBarIcon: ({ color }) => <Text style={{ fontSize: 22 }}>🕑</Text> }}
        />
        <Tab.Screen
          name="Favoriten"
          component={FavoritesScreen}
          options={{ tabBarIcon: ({ color }) => <Text style={{ fontSize: 22 }}>⭐</Text> }}
        />
      </Tab.Navigator>
    </NavigationContainer>
  );
}

/* ─────────────────────────────────────────────
   STYLES
───────────────────────────────────────────── */
const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: C.bg },
  scrollContent: { padding: 16, paddingBottom: 32 },
  largeTitle: { fontSize: 34, fontWeight: '700', letterSpacing: 0.37, marginBottom: 20, marginTop: 8 },
  card: {
    backgroundColor: C.card, borderRadius: 10,
    marginBottom: 10,
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.06, shadowRadius: 4 },
      android: { elevation: 2 },
    }),
  },
  sep: { height: 0.5, backgroundColor: C.sep, marginLeft: 16 },
  sectionHeader: { fontSize: 13, color: C.label2, textTransform: 'uppercase', letterSpacing: 0.4, marginBottom: 8, paddingLeft: 4 },

  // Input
  inputRow: { flexDirection: 'row', alignItems: 'center', padding: 13, paddingLeft: 16, minHeight: 44, gap: 12 },
  inputDot: { width: 9, height: 9, borderRadius: 5, flexShrink: 0 },
  textInput: { flex: 1, fontSize: 17, color: C.label },

  // Suggestions
  sugContainer: {
    position: 'absolute', top: '100%', left: 0, right: 0, zIndex: 999,
    backgroundColor: C.card, borderRadius: 10, overflow: 'hidden',
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.12, shadowRadius: 12 },
      android: { elevation: 8 },
    }),
  },
  sugRow: { flexDirection: 'row', alignItems: 'center', padding: 12, paddingLeft: 16, gap: 12, minHeight: 44 },
  sugSep: { borderTopWidth: 0.5, borderTopColor: C.sep },
  sugIcon: { fontSize: 20 },
  sugName: { fontSize: 16, color: C.label, flex: 1 },

  // Swap
  swapRow: { flexDirection: 'row', alignItems: 'center', marginLeft: 16, height: 28 },
  swapLine: { flex: 1, height: 0.5, backgroundColor: C.sep },
  swapBtn: {
    width: 28, height: 28, borderRadius: 14,
    backgroundColor: C.fill,
    alignItems: 'center', justifyContent: 'center',
  },
  swapIcon: { fontSize: 14, color: C.label2 },

  // Time
  timeCard: { flexDirection: 'row', padding: 0, overflow: 'hidden' },
  timePill: { flex: 1, padding: 13, fontSize: 14, fontWeight: '500', color: C.label, textAlign: 'center' },
  timePillText: { fontSize: 14, fontWeight: '500', color: C.label, textAlign: 'center' },
  timeSep: { width: 0.5, backgroundColor: C.sep },

  // CTA Button
  ctaBtn: {
    backgroundColor: C.brand, borderRadius: 10,
    padding: 14, alignItems: 'center', marginBottom: 8,
    ...Platform.select({
      ios: { shadowColor: C.brand, shadowOffset: { width: 0, height: 4 }, shadowOpacity: 0.3, shadowRadius: 8 },
      android: { elevation: 4 },
    }),
  },
  ctaDisabled: { opacity: 0.5 },
  ctaText: { color: '#fff', fontSize: 17, fontWeight: '600', letterSpacing: 0.35 },

  // Journey Card
  jCard: {
    backgroundColor: C.card, borderRadius: 10, marginBottom: 8, overflow: 'hidden',
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.06, shadowRadius: 4 },
      android: { elevation: 2 },
    }),
  },
  jTop: { flexDirection: 'row', padding: 14, alignItems: 'center' },
  jTimeCol: { flex: 1 },
  jTimeRight: { alignItems: 'flex-end' },
  jTimeBig: { fontSize: 22, fontWeight: '700', letterSpacing: -0.5, fontVariant: ['tabular-nums'] },
  delay: { fontSize: 11, fontWeight: '600', marginTop: 2 },
  jStation: { fontSize: 11, color: C.label2, marginTop: 4 },
  jMid: { alignItems: 'center', paddingHorizontal: 8 },
  jDur: { fontSize: 12, color: C.label2, fontWeight: '500' },
  jBar: { width: 60, height: 2, backgroundColor: '#D1D1D6', borderRadius: 2, marginVertical: 5, position: 'relative' },
  jBarDot: { position: 'absolute', width: 6, height: 6, borderRadius: 3, top: -2 },
  jChg: { fontSize: 11, color: C.label2 },
  jPills: { flexDirection: 'row', flexWrap: 'wrap', gap: 4, paddingHorizontal: 14, paddingBottom: 10 },
  jChevRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', padding: 8, gap: 4 },
  jChevText: { fontSize: 12, color: C.label3, fontWeight: '500' },
  jChevIcon: { fontSize: 10, color: C.label3 },

  // Pill
  pill: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 5 },
  pillText: { color: '#fff', fontSize: 12, fontWeight: '700', letterSpacing: 0.2 },

  // Detail / Legs
  detailWrap: { backgroundColor: C.bg, padding: 14, borderTopWidth: 0.5, borderTopColor: C.sep },
  legRow: { flexDirection: 'row', gap: 0 },
  legTimeline: { width: 28, alignItems: 'center', flexShrink: 0, paddingTop: 4 },
  legDot: { width: 10, height: 10, borderRadius: 5, flexShrink: 0, borderWidth: 2, borderColor: C.bg },
  legLine: { width: 2, borderRadius: 2, flex: 1, minHeight: 24, marginVertical: 2 },
  legBody: { flex: 1, paddingBottom: 14 },
  legTimeRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  legTime: { fontSize: 15, fontWeight: '700', fontVariant: ['tabular-nums'] },
  legStation: { fontSize: 14, fontWeight: '600', marginTop: 2 },
  legPlatform: { fontSize: 11, color: C.label2, backgroundColor: '#E5E5EA', borderRadius: 5, paddingHorizontal: 7, paddingVertical: 1, alignSelf: 'flex-start', marginTop: 3, fontWeight: '600' },
  legLineRow: { flexDirection: 'row', alignItems: 'center', gap: 8, paddingVertical: 8 },
  legDir: { fontSize: 13, color: C.label2, flex: 1 },
  walkText: { fontSize: 13, color: C.label2, flex: 1, paddingVertical: 8 },

  // Departures
  depHeader: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 4, marginBottom: 8 },
  depTitle: { fontSize: 20, fontWeight: '700' },
  starBtn: { fontSize: 26, color: '#C7C7CC' },
  depRow: { flexDirection: 'row', alignItems: 'center', padding: 12, paddingHorizontal: 16, gap: 12, minHeight: 52 },
  depSep: { borderTopWidth: 0.5, borderTopColor: C.sep },
  depInfo: { flex: 1, minWidth: 0 },
  depDest: { fontSize: 15, fontWeight: '500' },
  depPlat: { fontSize: 12, color: C.label2, marginTop: 2 },
  depRight: { alignItems: 'flex-end', flexShrink: 0 },
  depTime: { fontSize: 17, fontWeight: '700', fontVariant: ['tabular-nums'], letterSpacing: -0.3 },

  // Favorites
  favRow: { flexDirection: 'row', alignItems: 'center', padding: 12, paddingHorizontal: 16, gap: 12, minHeight: 52 },
  favIcon: { width: 36, height: 36, borderRadius: 9, backgroundColor: 'rgba(236,0,22,0.1)', alignItems: 'center', justifyContent: 'center' },
  favBody: { flex: 1 },
  favName: { fontSize: 16, fontWeight: '500' },
  favSub: { fontSize: 13, color: C.label2, marginTop: 1 },
  favDel: { fontSize: 20, color: '#C7C7CC', padding: 4 },

  // Empty State
  empty: { alignItems: 'center', paddingVertical: 48 },
  emptyIcon: { fontSize: 52, marginBottom: 12 },
  emptyText: { fontSize: 15, color: C.label2 },
  emptySubText: { fontSize: 13, color: C.label3, marginTop: 6, textAlign: 'center', paddingHorizontal: 24 },
});
