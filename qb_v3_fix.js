// qb_v3_fix.js — QB Complete Fix v3
// Run from ~/workspace: node qb_v3_fix.js
const fs = require('fs')
const FILE = 'frontend/app/admin/x7k2p/page.tsx'
let t = fs.readFileSync(FILE, 'utf8')

// ── FIX 1: qBV state → sessionStorage init ──────────────
if (t.includes("const [qBV,setQBV]=useState('home')")) {
  t = t.replace(
    "const [qBV,setQBV]=useState('home')",
    "const [qBV,setQBV]=useState(()=>{try{return sessionStorage.getItem('pr_qbv')||'home'}catch{return 'home'}})\n  const [formKey,setFormKey]=useState(0)"
  )
  console.log('✅ Fix 1: qBV sessionStorage + formKey added')
} else { console.log('⚠️  Fix 1: anchor not found') }

// ── FIX 2: addQ clear states — add formKey reset ─────────
const OLD_CLEAR = "qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';qChapR.current='';qTopicR.current='';qExpR.current='';qImageR.current='';setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('')"
const NEW_CLEAR = "qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';qChapR.current='';qTopicR.current='';qExpR.current='';qImageR.current='';setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('');setFormKey(k=>k+1)"
if (t.includes(OLD_CLEAR)) {
  t = t.replace(OLD_CLEAR, NEW_CLEAR)
  console.log('✅ Fix 2: formKey reset in addQ clear')
} else { console.log('⚠️  Fix 2: clear anchor not found') }

// ── FIX 3: Replace QB JSX block completely ───────────────
const QB_COMMENT = '{/* ══ QUESTION BANK ══ */}'
const SMART_COMMENT = '{/* ══ SMART GENERATOR ══ */}'
const si = t.indexOf(QB_COMMENT)
const smsi = t.indexOf(SMART_COMMENT)
if (si === -1 || smsi === -1) {
  console.error('ERROR: QB/SMART comment not found')
  process.exit(1)
}

// Build NCERT data object as a string to embed in JSX
const NCERT = {
  Physics: {
    '11th - Physical World': ['Nature of Physical Laws','Fundamental Forces'],
    '11th - Units & Measurements': ['SI Units','Significant Figures','Errors in Measurement','Dimensional Analysis'],
    '11th - Motion in Straight Line': ['Distance & Displacement','Velocity & Acceleration','Equations of Motion','Relative Motion'],
    '11th - Motion in a Plane': ['Vectors','Projectile Motion','Circular Motion','Relative Velocity'],
    '11th - Laws of Motion': ['Newtons Laws','Friction','Inertia','Momentum','Conservation of Momentum'],
    '11th - Work Energy Power': ['Work Done','Kinetic Energy','Potential Energy','Conservation of Energy','Power'],
    '11th - System of Particles': ['Centre of Mass','Angular Momentum','Torque','Rotational Motion'],
    '11th - Gravitation': ['Keplers Laws','Universal Gravitation','Gravitational Potential Energy','Satellites','Escape Velocity'],
    '11th - Mechanical Properties Solids': ['Stress & Strain','Youngs Modulus','Bulk Modulus','Shear Modulus'],
    '11th - Mechanical Properties Fluids': ['Pressure','Archimedes Principle','Bernoullis Theorem','Viscosity','Surface Tension'],
    '11th - Thermal Properties': ['Temperature','Thermal Expansion','Calorimetry','Heat Transfer','Radiation'],
    '11th - Thermodynamics': ['Zeroth Law','First Law','Second Law','Carnot Engine','Entropy'],
    '11th - Kinetic Theory': ['Kinetic Theory of Gases','Mean Free Path','Degrees of Freedom','Specific Heat Capacity'],
    '11th - Oscillations': ['Simple Harmonic Motion','Time Period','Amplitude','Damped Oscillations','Resonance'],
    '11th - Waves': ['Wave Motion','Speed of Sound','Superposition','Stationary Waves','Doppler Effect'],
    '12th - Electric Charges & Fields': ['Coulombs Law','Electric Field','Gauss Law','Electric Dipole','Electric Flux'],
    '12th - Electrostatic Potential': ['Electric Potential','Potential Energy','Capacitance','Dielectrics','Van de Graaff'],
    '12th - Current Electricity': ['Ohms Law','Kirchhoffs Laws','Wheatstone Bridge','Potentiometer','EMF & Internal Resistance'],
    '12th - Moving Charges & Magnetism': ['Biot Savart Law','Amperes Law','Cyclotron','Magnetic Force on Current'],
    '12th - Magnetism & Matter': ['Magnetic Dipole','Earths Magnetism','Diamagnetic Paramagnetic Ferromagnetic','Hysteresis'],
    '12th - Electromagnetic Induction': ['Faradays Law','Lenzs Law','Mutual Inductance','Self Inductance','Eddy Currents'],
    '12th - Alternating Current': ['AC Generator','RMS Values','Impedance','Resonance','Power Factor','Transformer'],
    '12th - Electromagnetic Waves': ['Displacement Current','EM Spectrum','Properties of EM Waves'],
    '12th - Ray Optics': ['Reflection','Refraction','Total Internal Reflection','Lenses','Optical Instruments','Prism'],
    '12th - Wave Optics': ['Huygens Principle','Interference','Diffraction','Polarisation','Youngs Double Slit'],
    '12th - Dual Nature of Radiation': ['Photoelectric Effect','De Broglie Wavelength','Davisson Germer'],
    '12th - Atoms': ['Bohr Model','Hydrogen Spectrum','Atomic Spectra'],
    '12th - Nuclei': ['Nuclear Binding Energy','Radioactivity','Nuclear Fission & Fusion','Half Life'],
    '12th - Semiconductor Electronics': ['P-N Junction','Diode','Transistor','Logic Gates','Rectification']
  },
  Chemistry: {
    '11th - Basic Concepts': ['Mole Concept','Stoichiometry','Limiting Reagent','Atomic Mass','Molecular Formula'],
    '11th - Structure of Atom': ['Bohr Model','Quantum Numbers','Orbitals','Electronic Configuration','Aufbau Principle'],
    '11th - Classification of Elements': ['Modern Periodic Table','Periodicity','Atomic Radius','Ionisation Enthalpy','Electronegativity'],
    '11th - Chemical Bonding': ['Ionic Bond','Covalent Bond','VSEPR Theory','Hybridisation','Hydrogen Bond','Molecular Orbital Theory'],
    '11th - States of Matter': ['Ideal Gas Equation','Kinetic Molecular Theory','Real Gases','Van der Waals'],
    '11th - Thermodynamics': ['Enthalpy','Entropy','Gibbs Energy','Hess Law','Bond Enthalpy'],
    '11th - Equilibrium': ['Law of Mass Action','Kp Kc','Le Chateliers Principle','Buffer Solution','pH & Ionic Equilibrium'],
    '11th - Redox Reactions': ['Oxidation Reduction','Oxidation Number','Balancing Redox','Electrochemical Series'],
    '11th - Hydrogen': ['Hydrogen Bonding','Water','Heavy Water','Hydrogen Peroxide'],
    '11th - s-Block Elements': ['Alkali Metals','Alkaline Earth Metals','Sodium Potassium Compounds','Calcium Compounds'],
    '11th - p-Block Elements': ['Group 13 14','Borax','Carbon Allotropes','Nitrogen Compounds','Phosphorus'],
    '11th - Organic Chemistry Basics': ['Hybridisation','Functional Groups','Homologous Series','IUPAC Nomenclature','Isomerism'],
    '11th - Hydrocarbons': ['Alkanes','Alkenes','Alkynes','Benzene','Aromaticity','Conformations'],
    '11th - Environmental Chemistry': ['Air Pollution','Water Pollution','Greenhouse Effect','Ozone Depletion'],
    '12th - Solid State': ['Crystal Systems','Packing Efficiency','Defects in Crystals','Magnetic Properties'],
    '12th - Solutions': ['Molarity Molality','Raoults Law','Colligative Properties','Osmosis','Van t Hoff Factor'],
    '12th - Electrochemistry': ['Galvanic Cells','Electrode Potential','Nernst Equation','Electrolysis','Faradays Laws'],
    '12th - Chemical Kinetics': ['Rate of Reaction','Order of Reaction','Arrhenius Equation','Activation Energy','Collision Theory'],
    '12th - Surface Chemistry': ['Adsorption','Catalysis','Colloids','Emulsions','Micelles'],
    '12th - General Principles Isolation': ['Thermodynamics of Extraction','Ellingham Diagram','Refining Methods'],
    '12th - p-Block 15to18': ['Nitrogen Family','Oxygen & Sulphur','Halogens','Noble Gases','Interhalogen Compounds'],
    '12th - d-Block Elements': ['Transition Metals','Properties','Potassium Dichromate','Potassium Permanganate'],
    '12th - Coordination Compounds': ['Ligands','CFSE','Crystal Field Theory','Isomerism','Bonding'],
    '12th - Haloalkanes Haloarenes': ['Nomenclature','SN1 SN2','Elimination','Aryl Halides'],
    '12th - Alcohols Phenols Ethers': ['Preparation','Properties','Reactions','Lucas Test','Victor Meyer'],
    '12th - Aldehydes & Ketones': ['Nucleophilic Addition','Aldol Condensation','Cannizzaro','Tollens Fehlings'],
    '12th - Carboxylic Acids': ['Acidity','Esterification','Hell Volhard Zelinsky','Derivatives'],
    '12th - Amines': ['Basicity','Diazonium Salts','Coupling Reactions','Hoffmann Bromamide'],
    '12th - Biomolecules': ['Carbohydrates','Proteins','Nucleic Acids','Vitamins','Enzymes'],
    '12th - Polymers': ['Addition Polymerisation','Condensation','Rubber','Plastics','Biodegradable'],
    '12th - Chemistry Everyday Life': ['Drugs','Food Preservatives','Cleansing Agents','Antimicrobials']
  },
  Biology: {
    '11th - The Living World': ['Characteristics of Living Organisms','Biodiversity','Taxonomy','Nomenclature','Keys'],
    '11th - Biological Classification': ['Five Kingdom Classification','Monera','Protista','Fungi','Viruses','Lichens'],
    '11th - Plant Kingdom': ['Algae','Bryophyta','Pteridophyta','Gymnosperms','Angiosperms','Alternation of Generations'],
    '11th - Animal Kingdom': ['Basis of Classification','Porifera','Coelenterata','Platyhelminthes','Annelida','Arthropoda','Chordata'],
    '11th - Morphology of Flowering Plants': ['Root Modifications','Stem Modifications','Leaf Modifications','Inflorescence','Flower','Fruit & Seed'],
    '11th - Anatomy of Flowering Plants': ['Meristematic Tissue','Permanent Tissue','Anatomy of Root Stem Leaf'],
    '11th - Structural Organisation Animals': ['Epithelial Tissue','Connective Tissue','Muscle Tissue','Neural Tissue','Frog Anatomy'],
    '11th - Cell Unit of Life': ['Cell Theory','Prokaryotic Cell','Eukaryotic Cell','Cell Organelles','Nucleus'],
    '11th - Biomolecules': ['Carbohydrates','Proteins','Lipids','Nucleic Acids','Enzymes','Metabolism'],
    '11th - Cell Cycle & Division': ['Cell Cycle','Mitosis','Meiosis','Significance'],
    '11th - Transport in Plants': ['Absorption','Apoplast Symplast','Transpiration','Ascent of Sap','Translocation'],
    '11th - Mineral Nutrition': ['Essential Elements','Mineral Deficiency','Nitrogen Fixation','Hydroponics'],
    '11th - Photosynthesis': ['Light Reaction','Calvin Cycle','C4 Pathway','CAM','Photorespiration'],
    '11th - Respiration in Plants': ['Glycolysis','Krebs Cycle','Electron Transport Chain','Fermentation'],
    '11th - Plant Growth': ['Phases of Growth','Plant Hormones','Auxin Gibberellin Cytokinin','Photoperiodism'],
    '11th - Digestion & Absorption': ['Human Digestive System','Digestion Process','Absorption','Disorders'],
    '11th - Breathing & Exchange': ['Respiratory System','Mechanism of Breathing','Gas Exchange','Respiratory Disorders'],
    '11th - Body Fluids': ['Blood Composition','Blood Groups','Coagulation','Lymph','Circulatory System','ECG'],
    '11th - Locomotion & Movement': ['Types of Movement','Muscle Contraction','Skeletal System','Joints','Disorders'],
    '11th - Neural Control': ['Neuron Structure','Nerve Impulse','Synapse','Human Brain','Spinal Cord','Sense Organs'],
    '11th - Chemical Coordination': ['Endocrine Glands','Hormones','Feedback Mechanism','Disorders'],
    '12th - Reproduction in Organisms': ['Modes of Reproduction','Vegetative Propagation','Asexual Reproduction'],
    '12th - Sexual Reproduction Plants': ['Flower Structure','Microsporogenesis','Megasporogenesis','Fertilisation','Embryo Development'],
    '12th - Human Reproduction': ['Male Reproductive System','Female Reproductive System','Gametogenesis','Menstrual Cycle','Fertilisation'],
    '12th - Reproductive Health': ['Contraception','Infertility','STDs','Amniocentesis'],
    '12th - Principles of Inheritance': ['Mendels Laws','Chromosomal Theory','Linkage','Mutation','Sex Determination'],
    '12th - Molecular Basis of Inheritance': ['DNA Structure','Replication','Transcription','Translation','Genetic Code','Regulation'],
    '12th - Evolution': ['Origin of Life','Darwins Theory','Natural Selection','Speciation','Human Evolution'],
    '12th - Human Health Disease': ['Immunity','Vaccines','Common Diseases','Cancer','Drugs & Alcohol'],
    '12th - Strategies Enhancement': ['Animal Breeding','Plant Breeding','Biofortification','SCP','Tissue Culture'],
    '12th - Microbes Human Welfare': ['Biogas','Biocontrol','Biofertilisers','Industrial Microbiology'],
    '12th - Biotechnology Principles': ['Recombinant DNA','Restriction Enzymes','Vectors','PCR','Gel Electrophoresis'],
    '12th - Biotechnology Applications': ['Transgenic Organisms','GM Crops','Gene Therapy','Molecular Diagnosis'],
    '12th - Organisms & Populations': ['Habitat & Niche','Population Interactions','Adaptations','Population Attributes'],
    '12th - Ecosystem': ['Ecosystem Structure','Food Chain','Energy Flow','Nutrient Cycling','Ecological Succession'],
    '12th - Biodiversity': ['Levels of Biodiversity','Loss of Biodiversity','Conservation Strategies','Hotspots'],
    '12th - Environmental Issues': ['Air Pollution','Water Pollution','Solid Waste','Greenhouse Effect','Ozone Depletion']
  },
  Math: {
    '11th - Sets': ['Types of Sets','Set Operations','Venn Diagrams','De Morgans Laws'],
    '11th - Relations & Functions': ['Types of Relations','Types of Functions','Composition','Domain Range'],
    '11th - Trigonometric Functions': ['Angles','Basic Identities','Values of Standard Angles','Graphs','Equations'],
    '11th - Mathematical Induction': ['Principle of Induction','Problems on Induction'],
    '11th - Complex Numbers': ['Algebra of Complex Numbers','Modulus Argument','Polar Form','De Moivres Theorem'],
    '11th - Linear Inequalities': ['Algebraic Solutions','Graphical Solutions','System of Inequalities'],
    '11th - Permutations & Combinations': ['Fundamental Principle','Permutations','Combinations','Applications'],
    '11th - Binomial Theorem': ['Binomial Expansion','General Term','Middle Term','Properties'],
    '11th - Sequences & Series': ['AP','GP','HP','Sum of Series','AM GM Inequality'],
    '11th - Straight Lines': ['Slope','Forms of Line Equation','Distance','Family of Lines'],
    '11th - Conic Sections': ['Circle','Parabola','Ellipse','Hyperbola','Standard Equations'],
    '11th - 3D Geometry Intro': ['Coordinates','Distance','Section Formula','Locus'],
    '11th - Limits & Derivatives': ['Limit of Function','Standard Limits','Derivatives','Differentiation Rules'],
    '11th - Statistics': ['Mean Median Mode','Variance','Standard Deviation','Coefficient of Variation'],
    '11th - Probability': ['Random Experiments','Events','Axiomatic Approach','Addition Theorem'],
    '12th - Relations & Functions': ['Binary Operations','Inverse Functions','Composition'],
    '12th - Inverse Trigonometry': ['Inverse Trig Functions','Properties','Equations'],
    '12th - Matrices': ['Matrix Operations','Types','Transpose','Adjoint','Inverse'],
    '12th - Determinants': ['Properties','Minors Cofactors','Area of Triangle','Cramers Rule'],
    '12th - Continuity & Differentiability': ['Continuity','Differentiability','Rolle Mean Value Theorem','Logarithmic Differentiation'],
    '12th - Applications of Derivatives': ['Rate of Change','Increasing Decreasing','Tangent Normal','Maxima Minima'],
    '12th - Integrals': ['Indefinite Integrals','Methods of Integration','Definite Integrals','Properties'],
    '12th - Applications of Integrals': ['Area Under Curves','Area Between Curves'],
    '12th - Differential Equations': ['Order & Degree','Formation','Variable Separable','Linear Equations'],
    '12th - Vector Algebra': ['Vectors','Addition','Dot Product','Cross Product','Scalar Triple Product'],
    '12th - 3D Geometry': ['Direction Cosines','Lines in Space','Planes','Angle Between'],
    '12th - Linear Programming': ['LPP','Graphical Method','Corner Point','Optimal Solution'],
    '12th - Probability': ['Conditional Probability','Bayes Theorem','Random Variables','Binomial Distribution']
  }
}

// Convert NCERT to JS string for embedding
const ncertStr = JSON.stringify(NCERT, null, 0)

const NEW_QB = `{/* ══ QUESTION BANK ══ */}
          {tab==='questions'&&(
            <div style={{position:'relative'}}>

              {/* HOME */}
              {qBV==='home'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',justifyContent:'space-between',marginBottom:16,flexWrap:'wrap',gap:10}}>
                    <div><div style={pageTitle}>📚 Question Bank</div><div style={pageSub}>{(questions||[]).length} questions · NEET Pattern Ready</div></div>
                    <button onClick={expQB} style={{...bg_,fontSize:11,padding:'6px 12px'}}>⬇️ Export CSV</button>
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'repeat(5,1fr)',gap:6,marginBottom:18}}>
                    {[{l:'Total',v:(questions||[]).length,c:'#A78BFA'},{l:'Physics',v:(questions||[]).filter(function(q){return q.subject==='Physics'}).length,c:'#60A5FA'},{l:'Chemistry',v:(questions||[]).filter(function(q){return q.subject==='Chemistry'}).length,c:'#F472B6'},{l:'Biology',v:(questions||[]).filter(function(q){return q.subject==='Biology'}).length,c:'#34D399'},{l:'Math',v:(questions||[]).filter(function(q){return q.subject==='Math'}).length,c:'#FBBF24'}].map(function(x){return(
                      <div key={x.l} style={{background:'rgba(255,255,255,0.04)',border:'1px solid '+x.c+'30',borderRadius:10,padding:'10px 6px',textAlign:'center'}}>
                        <div style={{fontSize:18,fontWeight:800,color:x.c}}>{x.v}</div>
                        <div style={{fontSize:9,color:'#64748b',marginTop:2}}>{x.l}</div>
                      </div>
                    )})}
                  </div>
                  <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:16,maxWidth:660,margin:'0 auto 18px'}}>
                    <div onClick={function(){setQBV('add');try{sessionStorage.setItem('pr_qbv','add')}catch{}}} style={{cursor:'pointer',background:'linear-gradient(135deg,rgba(77,159,255,0.12),rgba(160,80,255,0.08))',border:'1.5px solid rgba(77,159,255,0.3)',borderRadius:18,padding:'24px 16px',textAlign:'center'}}>
                      <div style={{fontSize:36,marginBottom:8,filter:'drop-shadow(0 0 10px rgba(77,159,255,0.5))'}}>➕</div>
                      <div style={{fontSize:15,fontWeight:800,color:'#E2E8F0',marginBottom:4}}>Add Question</div>
                      <div style={{fontSize:11,color:'#64748B',marginBottom:14}}>Manually add or AI auto-generate</div>
                      <div style={{display:'inline-block',background:'rgba(77,159,255,0.15)',border:'1px solid rgba(77,159,255,0.4)',borderRadius:8,padding:'6px 14px',fontSize:11,color:'#4D9FFF',fontWeight:700}}>Add Questions →</div>
                    </div>
                    <div onClick={function(){setQBV('preview');setQSec('all');try{sessionStorage.setItem('pr_qbv','preview')}catch{}}} style={{cursor:'pointer',background:'linear-gradient(135deg,rgba(0,229,160,0.08),rgba(160,80,255,0.06))',border:'1.5px solid rgba(0,229,160,0.25)',borderRadius:18,padding:'24px 16px',textAlign:'center'}}>
                      <div style={{fontSize:36,marginBottom:8,filter:'drop-shadow(0 0 10px rgba(0,229,160,0.4))'}}>👁️</div>
                      <div style={{fontSize:15,fontWeight:800,color:'#E2E8F0',marginBottom:4}}>Preview All Questions</div>
                      <div style={{fontSize:11,color:'#64748B',marginBottom:14}}>Browse, filter, edit section-wise</div>
                      <div style={{display:'inline-block',background:'rgba(0,229,160,0.12)',border:'1px solid rgba(0,229,160,0.35)',borderRadius:8,padding:'6px 14px',fontSize:11,color:'#00E5A0',fontWeight:700}}>Preview Bank →</div>
                    </div>
                  </div>
                  {(questions||[]).length>0&&(function(){
                    const all=questions||[];const tot=all.length||1
                    const ez=all.filter(function(q){return q.difficulty==='easy'}).length
                    const md=all.filter(function(q){return q.difficulty==='medium'}).length
                    const hd=all.filter(function(q){return q.difficulty==='hard'}).length
                    return(<div style={{background:'rgba(255,255,255,0.03)',border:'1px solid rgba(255,255,255,0.07)',borderRadius:12,padding:'12px 14px'}}>
                      <div style={{fontSize:11,color:'#94A3B8',fontWeight:600,marginBottom:8}}>📊 Difficulty Distribution</div>
                      {[{l:'Easy',v:ez,col:'#00C864'},{l:'Medium',v:md,col:'#FFB300'},{l:'Hard',v:hd,col:'#FF4D4D'}].map(function(x){
                        const pct=Math.round((x.v/tot)*100)
                        return(<div key={x.l} style={{display:'flex',alignItems:'center',gap:8,marginBottom:6}}>
                          <div style={{width:48,fontSize:10,color:x.col,fontWeight:600}}>{x.l}</div>
                          <div style={{flex:1,height:4,background:'rgba(255,255,255,0.06)',borderRadius:2}}><div style={{width:pct+'%',height:'100%',background:x.col,borderRadius:2}}/></div>
                          <div style={{width:58,fontSize:10,color:'#475569',textAlign:'right'}}>{x.v} ({pct}%)</div>
                        </div>)
                      })}
                    </div>)
                  })()}
                </div>
              )}

              {/* ADD QUESTION */}
              {qBV==='add'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',gap:10,marginBottom:14}}>
                    <button onClick={function(){setQBV('home');try{sessionStorage.setItem('pr_qbv','home')}catch{}}} style={{...bg_,padding:'6px 12px',fontSize:12}}>← Back</button>
                    <div><div style={pageTitle}>➕ Add Question to Bank</div><div style={pageSub}>Fill all details — saves instantly</div></div>
                  </div>
                  <div key={formKey} style={cs}>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:11}}>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>📝 Question Text (English) *</label>
                        <STextarea init='' onSet={function(v){qTxtR.current=v}} ph='Type the full question here…' rows={3} style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>🇮🇳 Hindi Text <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <STextarea init='' onSet={function(v){qHindiR.current=v}} ph='हिंदी में प्रश्न (वैकल्पिक)…' rows={2} style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div>
                        <label style={lbl}>📚 Subject *</label>
                        <select value={qSubj} onChange={function(e){setQSubj(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value=''>— Select Subject —</option>
                          <option value='Physics'>⚛️ Physics</option>
                          <option value='Chemistry'>🧪 Chemistry</option>
                          <option value='Biology'>🧬 Biology</option>
                          <option value='Math'>📐 Math</option>
                          <option value='Other'>📖 Other</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>🔢 Question Type</label>
                        <select value={qType} onChange={function(e){setQType(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value='SCQ'>SCQ — Single Correct</option>
                          <option value='MSQ'>MSQ — Multiple Correct</option>
                          <option value='Integer'>Integer Type</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>🎯 Difficulty</label>
                        <select value={qDiff} onChange={function(e){setQDiff(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value=''>— Select —</option>
                          <option value='easy'>🟢 Easy</option>
                          <option value='medium'>🟡 Medium</option>
                          <option value='hard'>🔴 Hard</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>✅ Correct Answer</label>
                        <select value={qAns} onChange={function(e){setQAns(e.target.value)}} style={{...inp,width:'100%'}}>
                          <option value=''>— Select Answer —</option>
                          <option value='A'>Option A</option>
                          <option value='B'>Option B</option>
                          <option value='C'>Option C</option>
                          <option value='D'>Option D</option>
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>📖 Chapter</label>
                        <SInput init='' onSet={function(v){qChapR.current=v}} ph='e.g. Electrostatics' style={inp}/>
                      </div>
                      <div>
                        <label style={lbl}>📌 Topic</label>
                        <SInput init='' onSet={function(v){qTopicR.current=v}} ph='e.g. Coulombs Law' style={inp}/>
                      </div>
                      {['SCQ','MSQ'].includes(qType)&&(<>
                        <div><label style={lbl}>Option A</label><SInput init='' onSet={function(v){qA.current=v}} ph='Option A…' style={inp}/></div>
                        <div><label style={lbl}>Option B</label><SInput init='' onSet={function(v){qB.current=v}} ph='Option B…' style={inp}/></div>
                        <div><label style={lbl}>Option C</label><SInput init='' onSet={function(v){qC.current=v}} ph='Option C…' style={inp}/></div>
                        <div><label style={lbl}>Option D</label><SInput init='' onSet={function(v){qD.current=v}} ph='Option D…' style={inp}/></div>
                      </>)}
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>💡 Explanation <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <STextarea init='' onSet={function(v){qExpR.current=v}} ph='Explain the correct answer…' rows={2} style={{...inp,resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>🖼️ Image URL <span style={{color:'#475569',fontSize:10}}>(optional)</span></label>
                        <SInput init='' onSet={function(v){qImageR.current=v}} ph='https://imgur.com/… (paste image link)' style={inp}/>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:10,marginTop:14,flexWrap:'wrap'}}>
                      <button onClick={addQ} disabled={savingQ} style={{...bp,flex:2,minWidth:150,opacity:savingQ?0.7:1}}>{savingQ?'⟳ Saving…':'✅ Add to Question Bank'}</button>
                      <button onClick={function(){
                        qTxtR.current='';qHindiR.current='';qA.current='';qB.current='';qC.current='';qD.current='';
                        qChapR.current='';qTopicR.current='';qExpR.current='';qImageR.current='';
                        setQSubj('');setQDiff('medium');setQType('SCQ');setQAns('');
                        setFormKey(function(k){return k+1});T('Form cleared')
                      }} style={{...bg_,padding:'8px 16px'}}>🗑️ Clear</button>
                    </div>
                  </div>
                  <div style={{display:'flex',justifyContent:'center',marginTop:18}}>
                    <div onClick={function(){setAiGO(true)}} style={{display:'flex',alignItems:'center',gap:10,background:'linear-gradient(135deg,rgba(77,159,255,0.15),rgba(168,85,247,0.2))',border:'1.5px solid rgba(168,85,247,0.45)',borderRadius:50,padding:'10px 22px',cursor:'pointer',boxShadow:'0 0 20px rgba(168,85,247,0.4)',animation:'qbpulse 2s infinite'}}>
                      <div style={{width:38,height:38,borderRadius:'50%',background:'linear-gradient(135deg,#4D9FFF,#A855F7)',display:'flex',alignItems:'center',justifyContent:'center',boxShadow:'0 0 12px rgba(168,85,247,0.6)',fontSize:18,flexShrink:0}}>🤖</div>
                      <div><div style={{fontSize:13,fontWeight:800,color:'#E2E8F0'}}>Upload Via AI</div><div style={{fontSize:10,color:'#A78BFA'}}>Auto-generate NCERT questions</div></div>
                      <div style={{fontSize:16,color:'#A78BFA'}}>✨</div>
                    </div>
                  </div>
                  <style dangerouslySetInnerHTML={{__html:'@keyframes qbpulse{0%,100%{box-shadow:0 0 20px rgba(168,85,247,0.4)}50%{box-shadow:0 0 35px rgba(168,85,247,0.7),0 0 55px rgba(77,159,255,0.3)}}'}}/>
                </div>
              )}

              {/* PREVIEW ALL */}
              {qBV==='preview'&&(
                <div>
                  <div style={{display:'flex',alignItems:'center',gap:8,marginBottom:10,flexWrap:'wrap'}}>
                    <button onClick={function(){setQBV('home');setBulkSel([]);try{sessionStorage.setItem('pr_qbv','home')}catch{}}} style={{...bg_,padding:'5px 11px',fontSize:11}}>← Back</button>
                    <div style={{flex:1}}><div style={pageTitle}>👁️ Preview All Questions</div><div style={pageSub}>{fQs.length} of {(questions||[]).length} shown</div></div>
                    <button onClick={function(){setStdPrv(function(p){return !p})}} style={{...bg_,fontSize:10,padding:'5px 10px',background:stdPrv?'rgba(0,229,160,0.12)':'rgba(255,255,255,0.05)',color:stdPrv?'#00E5A0':'#94A3B8'}}>{stdPrv?'🎓 ON':'🎓 View'}</button>
                    <button onClick={expQB} style={{...bg_,fontSize:10,padding:'5px 10px'}}>⬇️</button>
                    <button onClick={function(){setQBV('add');try{sessionStorage.setItem('pr_qbv','add')}catch{}}} style={{...bp,fontSize:10,padding:'5px 12px'}}>➕ Add</button>
                  </div>
                  <SInput init='' onSet={setQSearch} ph='🔍 Search questions, chapter, topic…' style={{...inp,marginBottom:8,fontSize:12}}/>
                  <div style={{display:'flex',gap:5,flexWrap:'wrap',marginBottom:7}}>
                    {[{k:'all',l:'All',col:'#A78BFA'},{k:'Physics',l:'⚛️ Phy',col:'#60A5FA'},{k:'Chemistry',l:'🧪 Chem',col:'#F472B6'},{k:'Biology',l:'🧬 Bio',col:'#34D399'},{k:'Math',l:'📐 Math',col:'#FBBF24'},{k:'Other',l:'📚 Other',col:'#94A3B8'}].map(function(x){
                      const cnt=x.k==='all'?(questions||[]).length:x.k==='Other'?(questions||[]).filter(function(q){return !['Physics','Chemistry','Biology','Math'].includes(q.subject||'')}).length:(questions||[]).filter(function(q){return q.subject===x.k}).length
                      const isA=qSec===x.k
                      return(<button key={x.k} onClick={function(){setQSec(x.k);setQBioSub('all')}} style={{padding:'4px 10px',borderRadius:16,border:'1.5px solid '+(isA?x.col:x.col+'22'),background:isA?x.col+'18':'transparent',color:isA?x.col:'#64748B',fontSize:10,fontWeight:isA?700:400,cursor:'pointer'}}>{x.l} ({cnt})</button>)
                    })}
                  </div>
                  {qSec==='Biology'&&(<div style={{display:'flex',gap:5,marginBottom:7}}>
                    {[{k:'all',l:'All Bio'},{k:'Zoology',l:'🦁 Zoo'},{k:'Botany',l:'🌿 Bot'}].map(function(x){
                      const isA=qBioSub===x.k
                      return(<button key={x.k} onClick={function(){setQBioSub(x.k)}} style={{padding:'3px 9px',borderRadius:12,border:'1px solid '+(isA?'#34D399':'rgba(52,211,153,0.2)'),background:isA?'rgba(52,211,153,0.12)':'transparent',color:isA?'#34D399':'#64748B',fontSize:10,cursor:'pointer'}}>{x.l}</button>)
                    })}
                  </div>)}
                  {fQs.length>0&&(function(){
                    const tot=fQs.length
                    const ez=fQs.filter(function(q){return q.difficulty==='easy'}).length
                    const md=fQs.filter(function(q){return q.difficulty==='medium'}).length
                    const hd=fQs.filter(function(q){return q.difficulty==='hard'}).length
                    return(<div style={{display:'flex',gap:10,alignItems:'center',marginBottom:8,padding:'5px 10px',background:'rgba(255,255,255,0.02)',borderRadius:7,flexWrap:'wrap'}}>
                      <span style={{color:'#475569',fontSize:10,fontWeight:600}}>Difficulty:</span>
                      {[{l:'Easy',v:ez,c:'#00C864'},{l:'Med',v:md,c:'#FFB300'},{l:'Hard',v:hd,c:'#FF4D4D'}].map(function(x){return(
                        <span key={x.l} style={{fontSize:10,color:x.c,fontWeight:600}}>{x.v} {x.l} <span style={{color:'#475569',fontWeight:400}}>({Math.round((x.v/tot)*100)}%)</span></span>
                      )})}
                    </div>)
                  })()}
                  {bulkSel.length>0&&(<div style={{display:'flex',alignItems:'center',gap:8,padding:'7px 12px',background:'rgba(255,60,60,0.07)',border:'1px solid rgba(255,60,60,0.2)',borderRadius:8,marginBottom:8,flexWrap:'wrap'}}>
                    <span style={{fontSize:11,color:'#FC8181',fontWeight:700}}>{bulkSel.length} selected</span>
                    <button onClick={blkDelQs} style={{...bd,fontSize:10,padding:'3px 12px'}}>🗑️ Delete</button>
                    <button onClick={function(){setBulkSel([])}} style={{...bg_,fontSize:10,padding:'3px 10px'}}>✕</button>
                  </div>)}
                  {fQs.length===0
                    ?<PageHero icon='❓' title='No Questions Found' subtitle={questions.length===0?'Loading questions…':'Try different search or section filter.'}/>
                    :<div style={{display:'flex',flexDirection:'column',gap:5}}>
                      {fQs.map(function(q,qi){
                        const isChk=bulkSel.includes(q._id)
                        const sCol=q.subject==='Physics'?'#60A5FA':q.subject==='Chemistry'?'#F472B6':q.subject==='Biology'?'#34D399':q.subject==='Math'?'#FBBF24':'#94A3B8'
                        const dCol=q.difficulty==='hard'?'#FF4D4D':q.difficulty==='easy'?'#00C864':'#FFB300'
                        return(
                          <div key={q._id||qi} style={{background:isChk?'rgba(77,159,255,0.05)':'rgba(255,255,255,0.02)',border:'1px solid '+(isChk?'rgba(77,159,255,0.2)':'rgba(255,255,255,0.05)'),borderLeft:'3px solid '+sCol+'55',borderRadius:9,padding:'9px 10px'}}>
                            <div style={{display:'flex',alignItems:'flex-start',gap:7}}>
                              <input type='checkbox' checked={isChk} onChange={function(e){if(e.target.checked)setBulkSel(function(p){return [...p,q._id]});else setBulkSel(function(p){return p.filter(function(x){return x!==q._id})})}} style={{marginTop:3,cursor:'pointer',accentColor:'#4D9FFF',flexShrink:0}}/>
                              <div style={{flex:1,minWidth:0}}>
                                <div style={{display:'flex',gap:4,marginBottom:4,flexWrap:'wrap',alignItems:'center'}}>
                                  <span style={{fontSize:9,color:'#4D9FFF',fontWeight:700,background:'rgba(77,159,255,0.1)',borderRadius:3,padding:'1px 5px'}}>#{qi+1}</span>
                                  <span style={{fontSize:9,fontWeight:600,padding:'1px 6px',borderRadius:4,background:sCol+'18',color:sCol,border:'1px solid '+sCol+'30'}}>{q.subject||'General'}</span>
                                  <span style={{fontSize:9,fontWeight:600,padding:'1px 6px',borderRadius:4,background:dCol+'18',color:dCol,border:'1px solid '+dCol+'30'}}>{q.difficulty||'?'}</span>
                                  <span style={{fontSize:9,padding:'1px 5px',borderRadius:3,background:'rgba(77,159,255,0.08)',color:'#4D9FFF'}}>{q.type||'SCQ'}</span>
                                </div>
                                <div onClick={function(){setSelQId(q._id)}} style={{cursor:'pointer',fontSize:12,color:'#CBD5E1',lineHeight:1.5,marginBottom:3}}>{(q.text||'').slice(0,140)}{(q.text||'').length>140?'…':''}</div>
                                {q.chapter&&<div style={{fontSize:10,color:'#475569'}}>📖 {q.chapter}{q.topic?' › '+q.topic:''}</div>}
                                {stdPrv&&(q.options||[]).length>0&&(<div style={{marginTop:6,display:'grid',gridTemplateColumns:'1fr 1fr',gap:3}}>
                                  {(q.options||[]).map(function(opt,oi){
                                    const ltr=String.fromCharCode(65+oi)
                                    const cIdx=Array.isArray(q.correct)?q.correct[0]:undefined
                                    const isC=(cIdx!==undefined&&String(cIdx)===String(oi))||(q.correctAnswer&&q.correctAnswer===ltr)
                                    return(<div key={oi} style={{padding:'3px 7px',borderRadius:5,fontSize:10,border:'1px solid '+(isC?'rgba(0,200,100,0.4)':'rgba(255,255,255,0.06)'),background:isC?'rgba(0,200,100,0.08)':'rgba(255,255,255,0.02)',color:isC?'#00C864':'#94A3B8'}}>
                                      <span style={{fontWeight:700,marginRight:4,color:isC?'#00C864':'#4D9FFF'}}>{ltr}.</span>{(opt||'').slice(0,28)}{isC&&' ✓'}
                                    </div>)
                                  })}
                                </div>)}
                              </div>
                              {/* HORIZONTAL action buttons */}
                              <div style={{display:'flex',gap:3,flexShrink:0,flexWrap:'nowrap'}}>
                                <button onClick={function(){setSelQId(q._id)}} style={{...bg_,padding:'4px 7px',fontSize:10,borderRadius:6}} title='Preview'>👁️</button>
                                <button onClick={function(){
                                  const ltrs=['A','B','C','D']
                                  const cIdx=Array.isArray(q.correct)&&q.correct.length>0?q.correct[0]:(q.correctAnswer?ltrs.indexOf(q.correctAnswer):0)
                                  setEditQD(Object.assign({},q,{correctLetter:ltrs[cIdx>=0?cIdx:0]||'A'}))
                                }} style={{...bg_,padding:'4px 7px',fontSize:10,borderRadius:6}} title='Edit'>✏️</button>
                                <button onClick={function(){dupQF(q)}} style={{...bg_,padding:'4px 7px',fontSize:10,borderRadius:6}} title='Duplicate'>📋</button>
                                <button onClick={async function(){if(confirm('Delete?')){const r=await fetch(API+'/api/questions/'+q._id,{method:'DELETE',headers:{Authorization:'Bearer '+token}});if(r.ok){setQuestions(function(p){return p.filter(function(x){return x._id!==q._id})});T('Deleted.')}else T('Failed','e')}}} style={{...bd,padding:'4px 7px',fontSize:10,borderRadius:6}} title='Delete'>🗑️</button>
                              </div>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  }
                </div>
              )}

              {/* AI GENERATE MODAL — Single Form */}
              {aiGO&&(function(){
                const NCERT=${ncertStr}
                const subj=aiGSub
                const chapters=subj&&NCERT[subj]?Object.keys(NCERT[subj]):[]
                const [aiSelChap,setAiSelChap]=React.useState(aiChR.current||'')
                const topics=aiSelChap&&NCERT[subj]&&NCERT[subj][aiSelChap]?NCERT[subj][aiSelChap]:[]
                return(
                  <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.88)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:14,overflowY:'auto'}}>
                    <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(77,159,255,0.3)',borderRadius:20,padding:20,width:'100%',maxWidth:460,maxHeight:'95vh',overflowY:'auto',boxShadow:'0 20px 60px rgba(0,0,0,0.6)'}}>
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:16}}>
                        <div>
                          <div style={{fontSize:14,fontWeight:800,color:'#E2E8F0'}}>🤖 AI Question Generator</div>
                          <div style={{fontSize:10,color:'#64748B',marginTop:2}}>NCERT Based · Auto answers & explanations</div>
                        </div>
                        <button onClick={function(){setAiGO(false);setAiGResult([])}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                      </div>
                      <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                        <div style={{gridColumn:'1/-1'}}>
                          <label style={lbl}>📚 Subject *</label>
                          <div style={{display:'grid',gridTemplateColumns:'repeat(4,1fr)',gap:6}}>
                            {['Physics','Chemistry','Biology','Math'].map(function(s){return(
                              <div key={s} onClick={function(){setAiGSub(s);aiChR.current='';aiTopR.current=''}}
                                style={{padding:'8px 4px',borderRadius:8,border:'1.5px solid '+(aiGSub===s?'rgba(77,159,255,0.5)':'rgba(255,255,255,0.08)'),background:aiGSub===s?'rgba(77,159,255,0.12)':'rgba(255,255,255,0.02)',cursor:'pointer',textAlign:'center'}}>
                                <div style={{fontSize:11,fontWeight:700,color:aiGSub===s?'#4D9FFF':'#94A3B8'}}>{s}</div>
                              </div>
                            )})}
                          </div>
                        </div>
                        <div style={{gridColumn:'1/-1'}}>
                          <label style={lbl}>📖 Chapter * <span style={{color:'#475569',fontSize:9}}>(select or type)</span></label>
                          <select onChange={function(e){if(e.target.value){aiChR.current=e.target.value;setAiSelChap(e.target.value)}}} style={{...inp,width:'100%',marginBottom:5}}>
                            <option value=''>— Select NCERT Chapter —</option>
                            {chapters.map(function(c){return <option key={c} value={c}>{c}</option>})}
                          </select>
                          <input defaultValue='' placeholder='Or type custom chapter…' onChange={function(e){aiChR.current=e.target.value;setAiSelChap(e.target.value)}} style={{...inp,width:'100%',fontSize:11}}/>
                        </div>
                        <div style={{gridColumn:'1/-1'}}>
                          <label style={lbl}>📌 Topic * <span style={{color:'#475569',fontSize:9}}>(select or type)</span></label>
                          <select onChange={function(e){if(e.target.value)aiTopR.current=e.target.value}} style={{...inp,width:'100%',marginBottom:5}}>
                            <option value=''>— Select NCERT Topic —</option>
                            {topics.map(function(tp){return <option key={tp} value={tp}>{tp}</option>})}
                          </select>
                          <input defaultValue='' placeholder='Or type custom topic…' onChange={function(e){aiTopR.current=e.target.value}} style={{...inp,width:'100%',fontSize:11}}/>
                        </div>
                        <div>
                          <label style={lbl}>🔢 Count <span style={{color:'#475569',fontSize:9}}>(1–30)</span></label>
                          <input type='number' min='1' max='30' defaultValue='10' onChange={function(e){setAiGCnt(e.target.value)}} style={{...inp,width:'100%'}}/>
                        </div>
                        <div>
                          <label style={lbl}>🎯 Difficulty</label>
                          <select value={aiGDiff} onChange={function(e){setAiGDiff(e.target.value)}} style={{...inp,width:'100%'}}>
                            <option value='easy'>🟢 Easy</option>
                            <option value='medium'>🟡 Medium</option>
                            <option value='hard'>🔴 Hard</option>
                          </select>
                        </div>
                        <div style={{gridColumn:'1/-1'}}>
                          <label style={lbl}>📋 Question Type</label>
                          <div style={{display:'flex',gap:6}}>
                            {['SCQ','MSQ','Integer'].map(function(tp){return(
                              <button key={tp} style={{...bg_,fontSize:10,padding:'4px 10px',flex:1}} onClick={function(){}}>{tp}</button>
                            )})}
                          </div>
                        </div>
                      </div>
                      {aiGResult.length>0&&(<div style={{marginBottom:12}}>
                        <div style={{fontSize:11,fontWeight:700,color:'#00C864',marginBottom:6}}>✅ {aiGResult.length} Questions Generated!</div>
                        <div style={{maxHeight:100,overflowY:'auto',display:'flex',flexDirection:'column',gap:3,marginBottom:8}}>
                          {aiGResult.map(function(q,i){return(
                            <div key={i} style={{padding:'4px 8px',background:'rgba(0,200,100,0.05)',borderRadius:5,fontSize:10,color:'#CBD5E1'}}>Q{i+1}: {(q.text||'').slice(0,65)}…</div>
                          )})}
                        </div>
                        <button onClick={saveAiQs} style={{...bp,width:'100%',fontSize:11,marginBottom:8}}>💾 Save All {aiGResult.length} to Question Bank</button>
                      </div>)}
                      <button onClick={aiGF} disabled={aiGLoading} style={{...bp,width:'100%',opacity:aiGLoading?0.7:1}}>
                        {aiGLoading?'⟳ Generating NCERT Questions…':'🤖 Generate Questions'}
                      </button>
                      <div style={{fontSize:9,color:'#475569',textAlign:'center',marginTop:6}}>Generates NCERT-based questions with correct answers & explanations</div>
                    </div>
                  </div>
                )
              })()}

              {/* QUESTION PREVIEW MODAL */}
              {selQId&&(function(){
                const qi=(questions||[]).findIndex(function(q){return q._id===selQId})
                const q=(questions||[])[qi]
                if(!q)return null
                const sCol=q.subject==='Physics'?'#60A5FA':q.subject==='Chemistry'?'#F472B6':q.subject==='Biology'?'#34D399':'#A78BFA'
                const dCol=q.difficulty==='hard'?'#FF4D4D':q.difficulty==='easy'?'#00C864':'#FFB300'
                return(
                  <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.9)',zIndex:1000,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                    <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(77,159,255,0.2)',borderRadius:20,padding:20,width:'100%',maxWidth:500,maxHeight:'90vh',overflowY:'auto'}}>
                      <div style={{display:'flex',justifyContent:'space-between',alignItems:'flex-start',marginBottom:12}}>
                        <div>
                          <div style={{display:'flex',gap:4,flexWrap:'wrap',marginBottom:4}}>
                            <span style={{fontSize:9,fontWeight:600,padding:'2px 7px',borderRadius:4,background:sCol+'18',color:sCol,border:'1px solid '+sCol+'30'}}>{q.subject||'General'}</span>
                            <span style={{fontSize:9,fontWeight:600,padding:'2px 7px',borderRadius:4,background:dCol+'18',color:dCol,border:'1px solid '+dCol+'30'}}>{q.difficulty||'?'}</span>
                            <span style={{fontSize:9,padding:'2px 7px',borderRadius:4,background:'rgba(77,159,255,0.1)',color:'#4D9FFF'}}>{q.type||'SCQ'}</span>
                          </div>
                          <div style={{fontSize:10,color:'#475569'}}>Q{qi+1} of {(questions||[]).length}</div>
                        </div>
                        <button onClick={function(){setSelQId(null)}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                      </div>
                      <div style={{fontSize:13,color:'#E2E8F0',lineHeight:1.7,marginBottom:10,padding:'11px 13px',background:'rgba(255,255,255,0.03)',borderRadius:10,border:'1px solid rgba(255,255,255,0.06)'}}>{q.text}</div>
                      {q.hindiText&&<div style={{fontSize:11,color:'#94A3B8',marginBottom:10,fontStyle:'italic',padding:'6px 11px',background:'rgba(255,255,255,0.02)',borderRadius:8}}>{q.hindiText}</div>}
                      {(q.options||[]).length>0&&(<div style={{display:'flex',flexDirection:'column',gap:5,marginBottom:10}}>
                        {(q.options||[]).map(function(opt,oi){
                          const ltr=String.fromCharCode(65+oi)
                          const cIdx=Array.isArray(q.correct)&&q.correct.length>0?q.correct[0]:undefined
                          const isC=(cIdx!==undefined&&String(cIdx)===String(oi))||(q.correctAnswer&&q.correctAnswer===ltr)
                          return(<div key={oi} style={{padding:'7px 11px',borderRadius:7,border:'1px solid '+(isC?'rgba(0,200,100,0.4)':'rgba(255,255,255,0.07)'),background:isC?'rgba(0,200,100,0.08)':'rgba(255,255,255,0.02)'}}>
                            <span style={{fontWeight:700,color:isC?'#00C864':'#4D9FFF',marginRight:8}}>{ltr}.</span>
                            <span style={{fontSize:12,color:isC?'#E2E8F0':'#94A3B8'}}>{opt}</span>
                            {isC&&<span style={{marginLeft:8,fontSize:10,color:'#00C864',fontWeight:700}}>✓ Correct</span>}
                          </div>)
                        })}
                      </div>)}
                      {(q.chapter||q.topic||q.explanation)&&(<div style={{fontSize:11,color:'#64748B',marginBottom:10,lineHeight:1.6}}>
                        {q.chapter&&<div>📖 {q.chapter}{q.topic?' › '+q.topic:''}</div>}
                        {q.explanation&&<div style={{color:'#94A3B8',marginTop:4}}>💡 {q.explanation}</div>}
                      </div>)}
                      <div style={{display:'flex',gap:7}}>
                        <button onClick={function(){if(qi>0)setSelQId((questions||[])[qi-1]._id)}} disabled={qi===0} style={{...bg_,flex:1,opacity:qi===0?0.35:1,fontSize:11}}>← Prev</button>
                        <button onClick={function(){
                          const ltrs=['A','B','C','D']
                          const cIdx=Array.isArray(q.correct)&&q.correct.length>0?q.correct[0]:(q.correctAnswer?ltrs.indexOf(q.correctAnswer):0)
                          setEditQD(Object.assign({},q,{correctLetter:ltrs[cIdx>=0?cIdx:0]||'A'}))
                          setSelQId(null)
                        }} style={{...bp,flex:1,fontSize:11}}>✏️ Edit</button>
                        <button onClick={function(){if(qi<(questions||[]).length-1)setSelQId((questions||[])[qi+1]._id)}} disabled={qi>=(questions||[]).length-1} style={{...bg_,flex:1,opacity:qi>=(questions||[]).length-1?0.35:1,fontSize:11}}>Next →</button>
                      </div>
                    </div>
                  </div>
                )
              })()}

              {/* EDIT MODAL */}
              {editQD&&(
                <div style={{position:'fixed',inset:0,background:'rgba(0,0,0,0.9)',zIndex:1001,display:'flex',alignItems:'center',justifyContent:'center',padding:14}}>
                  <div style={{background:'linear-gradient(160deg,#0D1B2A,#0F1E30)',border:'1px solid rgba(255,184,0,0.25)',borderRadius:20,padding:20,width:'100%',maxWidth:490,maxHeight:'90vh',overflowY:'auto'}}>
                    <div style={{display:'flex',justifyContent:'space-between',alignItems:'center',marginBottom:14}}>
                      <div style={{fontSize:13,fontWeight:800,color:'#E2E8F0'}}>✏️ Edit Question</div>
                      <button onClick={function(){setEditQD(null)}} style={{...bg_,padding:'3px 8px',fontSize:11}}>✕</button>
                    </div>
                    <div style={{display:'grid',gridTemplateColumns:'1fr 1fr',gap:10,marginBottom:12}}>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Question Text *</label>
                        <textarea value={editQD.text||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{text:e.target.value})})}} rows={3} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Hindi Text <span style={{color:'#475569',fontSize:9}}>(optional)</span></label>
                        <textarea value={editQD.hindiText||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{hindiText:e.target.value})})}} rows={2} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                      <div>
                        <label style={lbl}>Subject</label>
                        <select value={editQD.subject||'Physics'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{subject:e.target.value})})}} style={{...inp,width:'100%'}}>
                          {['Physics','Chemistry','Biology','Math','Other'].map(function(s){return <option key={s} value={s}>{s}</option>})}
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>Difficulty</label>
                        <select value={editQD.difficulty||'medium'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{difficulty:e.target.value})})}} style={{...inp,width:'100%'}}>
                          {['easy','medium','hard'].map(function(d){return <option key={d} value={d}>{d}</option>})}
                        </select>
                      </div>
                      <div>
                        <label style={lbl}>Chapter</label>
                        <input value={editQD.chapter||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{chapter:e.target.value})})}} style={{...inp,width:'100%'}}/>
                      </div>
                      <div>
                        <label style={lbl}>Topic</label>
                        <input value={editQD.topic||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{topic:e.target.value})})}} style={{...inp,width:'100%'}}/>
                      </div>
                      {(editQD.options&&editQD.options.length>0?editQD.options:['','','','']).map(function(opt,oi){return(
                        <div key={oi}>
                          <label style={lbl}>Option {String.fromCharCode(65+oi)}</label>
                          <input value={opt||''} onChange={function(e){
                            const opts=[...((editQD.options&&editQD.options.length>0)?editQD.options:['','','',''])]
                            opts[oi]=e.target.value
                            setEditQD(function(p){return Object.assign({},p,{options:opts})})
                          }} style={{...inp,width:'100%'}}/>
                        </div>
                      )})}
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>✅ Correct Answer</label>
                        <select value={editQD.correctLetter||'A'} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{correctLetter:e.target.value})})}} style={{...inp,width:'100%'}}>
                          <option value='A'>Option A</option>
                          <option value='B'>Option B</option>
                          <option value='C'>Option C</option>
                          <option value='D'>Option D</option>
                        </select>
                      </div>
                      <div style={{gridColumn:'1/-1'}}>
                        <label style={lbl}>Explanation</label>
                        <textarea value={editQD.explanation||''} onChange={function(e){setEditQD(function(p){return Object.assign({},p,{explanation:e.target.value})})}} rows={2} style={{...inp,width:'100%',resize:'vertical'}}/>
                      </div>
                    </div>
                    <div style={{display:'flex',gap:8}}>
                      <button onClick={function(){setEditQD(null)}} style={{...bg_,flex:1,fontSize:11}}>Cancel</button>
                      <button onClick={function(){editQF(editQD._id,editQD)}} disabled={savingEQ} style={{...bp,flex:2,fontSize:11,opacity:savingEQ?0.7:1}}>{savingEQ?'⟳ Saving…':'💾 Save Changes'}</button>
                    </div>
                  </div>
                </div>
              )}

            </div>
          )}`

// Find exact QB block to replace
const qbEnd = t.indexOf(SMART_COMMENT, si)
if (qbEnd === -1) { console.error('ERROR: SMART_COMMENT not found after QB'); process.exit(1) }
t = t.slice(0, si) + NEW_QB + '\n\n          ' + t.slice(qbEnd)
console.log('✅ Fix 3: QB JSX completely replaced with v3')

fs.writeFileSync(FILE, t)
console.log('')
console.log('✅ ALL v3 FIXES DONE!')
