**VESPERA  /  ENGINEERING ROADMAP** 

# **VESPERA ENGINEERING ROADMAP** 

Adaptive Music Intelligence Engine 

#### **THE MASTER BUILD PLAN** 

A research-backed, implementation-first plan for turning the current Flutter app into a measurable, user-controlled adaptive music system. 

#### **THE PRODUCT THESIS** 

Vespera converts a listener’s intent into a verifiable recommendation policy, constructs a listening session against that policy, and changes the unplayed queue when reason-coded feedback shows that the current plan is wrong. 

##### VERSION   1.1 

**DATE** 14 November 2026 

**SCOPE** Whole Vespera application: Flutter client, FastAPI backend, catalog, intelligence, evaluation and operational controls **BUILD PRINCIPLE** Preserve the current Flutter/Twilight visual shell. Rebuild the logic underneath it. 

This document is the source of truth for implementation order. Version 1.1 narrows the first release to a runnable, rights-aware acceptance scenario and resolves playback-duration, cold-start, UI-scope, test-set, authentication and deployment blockers. A phase is not complete because its UI exists; it is complete only when its acceptance tests pass. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  1 

**VESPERA  /  ENGINEERING ROADMAP** 

## **1. Executive decision** 

Vespera is not being built to replace Spotify, Apple Music or YouTube Music as a licensed streaming service. It is a listenercontrolled music-intelligence layer that discovers, ranks and sequences music from sources Vespera is authorized to use. The first end-to-end session must use full-length, permitted catalog streams from a rights-reviewed non-commercial prototype source; iTunes is restricted to compliant catalog promotion/search and external handoff, not session-duration playback. 

### **What Vespera is** 

#### **ONE-SENTENCE DEFINITION** 

Vespera is an adaptive music intelligence system that compiles natural-language listening intent into a scoped policy, retrieves and ranks eligible tracks, sequences a listening session, and learns from contextual feedback without confusing temporary session needs with durable taste. 

### **The core loop** 



<!-- Start of picture text -->
THE PRODUCT LOOP: PLAN — PLAY ~ LEARN ~ REPLAN<br>)<br>01 03 ( 4 ) ) 06<br>Intent _. Contract | Plan _ Play _ Observe | Update<br><!-- End of picture text -->

_The loop is the product. The chat box, orb, music cards and analytics are presentation surfaces for this underlying system._ 

### **Milestone 1 proof target** 

|**V1 must prove**|**V1 does not need to prove**|
|---|---|
|**A listener can state a goal and constraints in ordinary**<br>**language.**|A catalog containing tens of millions of commercially playable<br>songs.|
|**The intent is converted into typed, testable policy fields.**|A proprietary foundation model or a 20-agent swarm.|
|**Hard constraints are enforced against known metadata.**|Perfect emotion recognition or clinical mood improvement.|
|**Recommendations are ranked and sequenced, not invented by**<br>**an LLM.**|A custom music streaming CDN, P2P delivery or DAW.|
|**A reason-coded interaction can change the remaining queue.**|Production-grade collaborative filtering from sparse data.|
|**Every recommendation has an evidence-backed trace.**|An unsupported promise to outperform major platforms.|



Milestone 1 is a non-commercial proof on 50-100 Jamendo tracks, not a mainstream-catalog session built from 30-second iTunes snippets. The planner must produce 30 minutes from verified playable_ms, and the contract must disclose any soft preference that the catalog cannot verify. 

### **Definition of a successful first release** 

- The playback UI reflects the actual player state and the queue is real. 

- Twilight sends requests to a working backend service and displays real catalog results. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  2 

**VESPERA  /  ENGINEERING ROADMAP** 

- A session contract is stored and checked before a track can be recommended. 

- A skip reason changes the current session policy when appropriate; it does not automatically rewrite long-term taste. 

- The system can explain each selected track using facts stored in its recommendation trace. 

- Evaluation compares the adaptive system against a simple baseline and reports limitations honestly. 

## **2. Current repository baseline** 

This baseline was checked against the live public repository on 14 November 2026. GitHub reports the repository was last pushed on 17 August 2026. The current tree still reflects a prototype architecture. The backend also hard-codes Groq model ID llama3-8b-8192, which Groq retired on 30 August 2025; it must be removed from active configuration before the intent compiler is wired [R19]. Treat the following as the starting backlog, not as completed capabilities. 

|**Area**|**Observed state**|**Engineering consequence**|
|---|---|---|
|**Flutter / Twilight**|The Twilight screen and visual components exist. Its<br>main interaction pattern is still a front-end shell rather<br>than a complete assistant workflow.|Freeze the current visual design. Wire existing controls to a<br>single service and typed API.|
|Playback|AudioPlayerService currently resolves a title through<br>iTunes Search and plays a 30-second preview. Apple<br>restricts such previews to promotional use and<br>documents an approximately 20-call/minute Search API<br>limit [R18].|Remove iTunes preview playback from the player. Use<br>Jamendo full streams for the M1 acceptance session only after<br>rights checks; use Apple catalog search and external handoff.<br>Any compliant promotional preview is separate from session<br>playback and contributes 0 ms.|
|**Playback state**|The service stores currentTitle but does not expose a<br>complete current-track, queue, position and error state<br>contract.|Mini-player and Now Playing must subscribe to one<br>authoritative player state.|
|Backend / AI|main.py maps time/weather to broad categories<br>using Groq and currently hard-codes llama3-<br>8b-8192, retired by Groq in August 2025 [R19].|Replace the category mapper with a typed intent compiler.<br>Put GROQ_MODEL in environment configuration and<br>verify model availability before release.|
|**Track model**|PlaylistItem stores title, subtitle, image_url,<br>search_query and optional audio_id.|This is insufficient for ranking, provider mapping, deduplication,<br>explainability or rights-aware playback.|
|**Catalog discovery**|The backend uses ytmusicapi and a YouTube search<br>fallback for catalog discovery.|Do not make unofficial extraction a production playback<br>dependency. Introduce provider adapters and explicit playback<br>capabilities.|
|**Persistence /**<br>**learning**|The reviewed main.py does not establish a proper<br>persistent user taste, session, event or<br>recommendation-trace layer.|Build database-backed events before claiming Music DNA or<br>personalization.|
|**Architecture**|The backend is concentrated in main.py. The repository<br>also contains a separate React/TanStack Twilight<br>prototype directory.|Use Flutter as the sole production client. Refactor the FastAPI<br>backend as a modular monolith.|



#### **NON-NEGOTIABLE** 

Do not add more visible Twilight features yet. The first development cycle is playback truth, canonical track data, event capture and a functioning request/response path. More cards on top of fake state will make the app harder to repair. 

### **UI freeze** 

- Keep the Twilight screen’s composition, colors, type, spacing, assets and card geometry unchanged. 

- Milestone 1 permits exactly two new surfaces built from existing visual components: (1) a contract-summary bottom sheet that also contains the 3-5 seed-track picker, and (2) a skip-reason sheet. No new main screen or redesign. 

- Treat the React/TanStack directory as a visual reference only. Do not create a second production client. 

- Keep the orb visual identity; bind it to real states only after the core request and player states exist. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  3 

**VESPERA  /  ENGINEERING ROADMAP** 

## **3. Industry and research reality** 

The old idea list overvalues features and undervalues the decision process behind them. Current products already cover prompt-to-playlist and conversational discovery. Recent research also covers intent-specific models, natural-language taste profiles, multi-objective ranking and artist-aware cold start. The opportunity is not to claim those concepts are untouched; it is to build and evaluate a coherent system that combines them with scope-safe memory and live session adaptation. 

|**Evidence**|**What it already establishes**|**What Vespera should conclude**|
|---|---|---|
|**Spotify Prompted Playlist [R1]**|Listeners can describe a vibe, scenario or cultural moment;<br>Spotify generates and refreshes a playlist using listening<br>history and music signals.|Prompt-to-playlist is table stakes. Vespera must do more<br>than parse a prompt and return a list.|
|**YouTube Music Ask Music**<br>**[R2]**|A conversational discovery experience spans a catalog<br>YouTube describes as 300M+ songs and supports queue<br>customization and artist exploration.|A conversational music surface is not a moat.|
|**Spotify Textual User Taste**<br>**[R3]**|A natural-language taste representation is deployed at scale.<br>The paper reports useful predictive signal and identifies<br>limitations with negation and short-term temporal adaptation.|Test explicit negatives, context scope and short-lived<br>preferences. Avoid allowing one session instruction to<br>corrupt the durable profile.|
|**Kiite intent-based**<br>**recommendation models [R4]**|A real music service supported multiple user-created intent-<br>specific models; the study analyzed 1,116 models created by<br>417 users.|User-controlled intent models are not new. Vespera’s<br>research hypothesis is their integration with session<br>contracts, reason-coded feedback and sequence<br>replanning.|
|**Spotify SPDD / KDD 2026 [R5]**|An inference-time primal-dual decoder dynamically balances<br>relevance and auxiliary objectives during sequential<br>recommendation.|Use constraint-aware sequential selection. Begin with a<br>simple deterministic planner; do not claim to reproduce<br>Spotify-scale generative optimization.|
|**Beyond Skipping [R6]**|A 2026 Zenodo record describes a study distinguishing Listen,<br>Not now and Skip, with reasons. The record is anonymous<br>supplementary material, not strong standalone evidence of a<br>settled result.|Treat it as motivation for a pilot experiment, not as a<br>proven industry-wide finding.|
|**CHI 2026 discoverability audit**<br>**[R7]**|Think-aloud sessions with 20 listeners surfaced perceived<br>narrow niches, commercial influence and societal bias in music<br>discovery.|Build user-visible controls and audit repeated exposure.<br>Do not claim private platform ranking logic is knowable.|
|**Music metadata research [R8]**|2026 Oxford papers describe persistent interoperability,<br>attribution and discoverability problems, especially where<br>metadata is missing or mis-specified.|Metadata provenance and coverage are engineering<br>features, not clerical details.|
|**CLaMP 3 [R9]**|Cross-modal and cross-lingual music retrieval, including<br>generalization to unseen languages, is already a research<br>direction.|Do not claim “multilingual AI” is novel. Validate code-<br>mixing, transliteration and metadata coverage for target<br>Indian repertoires.|



INTERNAL BUILD DOCUMENT  •  v1.1  •  4 

**VESPERA  /  ENGINEERING ROADMAP** 

## **4. The defensible Vespera opportunity** 

### **The product gap** 

Large platforms are investing in recommendation control, natural-language taste profiles, conversational discovery, AI provenance and multi-objective recommendation. That means there is no credible basis to claim that Vespera has discovered a wholly empty category. The defensible product hypothesis is narrower: listeners should be able to state a temporary goal, define hard and soft constraints, see the policy that will govern a session, correct the system with a reason, and have the remaining queue adapt while keeping long-term taste separate. 

#### **RESEARCH HYPOTHESIS** 

A recommendation system with scope-aware intent memory, verifiable session contracts and reason-coded adaptive sequencing will satisfy specific listening goals better than a static prompt-generated playlist, without a material loss in perceived relevance. 

### **Four testable hypotheses** 

|**ID**|**Hypothesis**|**How to test it**|
|---|---|---|
|**H1 - Scope safety**|Separating global taste, context preference and session-<br>only rules reduces preference leakage from temporary<br>instructions.|Give the same listeners conflicting instructions across<br>contexts; audit whether a temporary “not tonight” instruction<br>changes global preferences.|
|**H2 - Contract**<br>**control**|Explicit hard constraints and user-controlled novelty<br>targets increase constraint satisfaction and perceived<br>control.|Compare a free-form prompt playlist with a validated policy<br>contract; measure violation rate and user-rated controllability.|
|**H3 - Reason-aware**<br>**adaptation**|Reason-coded feedback leads to better next-queue<br>choices than treating every skip as a dislike.|Compare skip-only updates against skip + reason + context;<br>evaluate accepted next tracks and session goal satisfaction.|
|**H4 - Local**<br>**discovery quality**|Metadata confidence and multilingual retrieval improve<br>discovery coverage for under-documented Indian-<br>language tracks.|Build a human-labelled query set in English, Hindi, Hinglish<br>and one additional language; report recall and coverage<br>separately by language.|



### **What counts as innovation here** 

- Not the use of an LLM, vector database or agent framework. 

- Not mood playlists, lyric search, a taste graph or recommendation explanations in isolation. 

- The engineering contribution is the integrated policy-and-feedback loop, its scope guarantees, and a reproducible evaluation showing where it works and where it fails. 

- Do not advertise “first”, “unique” or “industry-first” without a systematic prior-art review and evidence. 

### **Proposed signature system: Vespera Session Contract** 

A Session Contract is a typed, inspectable policy object created from natural language. It distinguishes hard constraints from soft preferences, records the scope and expiry of each instruction, and becomes the source of truth for retrieval, ranking, sequencing, explanation and replanning. 

SessionContract goal: deep_focus | duration_min: 50 scope: current_session | expires_at: session_end hard: instrumental_after_min=10; max_artist_repeats=2 soft: energy=[0.30,0.45,0.60]; novelty=0.35; experimental_max=0.20 discovery: familiar=0.40; adjacent=0.40; frontier=0.20 unknown_metadata: exclude_for_hard_constraints; policy_version=1 

INTERNAL BUILD DOCUMENT  •  v1.1  •  5 

**VESPERA  /  ENGINEERING ROADMAP** 

## **5. Twilight: behavior behind the existing UI** 

Do not redesign the Twilight surface. Wire each existing affordance to a well-defined action. All interactions should use the same Twilight service and the same policy/compiler pipeline unless the action is purely local navigation. 

|**Existing element**|**Required behavior**|**Implementation rule**|
|---|---|---|
|Featured dropdown|Keep the default mode fixed for Milestone 1.|Do not add another overlay in M1; activate mode<br>selection after the loop passes.|
|Improve my mood card|Deferred beyond Milestone 1; the typed prompt path<br>can still express a listening goal.|Do not claim the Mood Journey feature is complete until<br>trajectory planning and feedback replanning are tested.|
|Music DNA card|Deferred beyond Milestone 1; show a small<br>availability message if tapped.|No analytics screen before real events and non-synthetic<br>history exist.|
|Semantic search card|Populate the existing chat input with a sample query<br>and use the shared request path.|No separate search workflow or new screen.|
|**Semantic search card**|Run natural-language search through the intent compiler<br>and retrieval/ranking pipeline.|The LLM returns structured query constraints. It must not<br>invent track titles.|
|+ button|No Add Context sheet in Milestone 1; show a brief<br>unavailable message.|Defer the context sheet until the session contract and<br>feedback loop work.|
|Microphone|No voice flow in Milestone 1; show a brief<br>unavailable message.|Defer the microphone and speech-to-text surface until<br>after the loop works.|
|**Microphone**|Speech-to-text, then send recognized text through the<br>same request path.|Local/on-device speech recognition where practical; text is<br>the input to the intent compiler.|
|**Blue submit /**<br>**AudioLines button**|Submit the current request, display progress, receive a<br>typed response and render results.|Disable duplicate submission; use request IDs; display<br>recoverable errors.|
|**Energy orb**|Reflect agent/player state while keeping its current<br>visual design.|Bind animation state to real state transitions; never imply<br>“thinking” when no request is running.|



### **Single request path** 

Twilight UI action 

- -> TwilightService 

- -> POST /api/v1/twilight/agent 

- -> authenticate + validate request 

- -> compile intent into SessionContract 

- -> retrieve / filter / rank / sequence 

- -> persist session + recommendation trace 

- -> return typed response 

- -> Flutter renders cards / session / explanations 

_Do not implement one model prompt for semantic search, a different model prompt for suggestions, another for the mood card and a fourth for voice. These are interaction modes entering one shared engine with different policy presets._ 

INTERNAL BUILD DOCUMENT  •  v1.1  •  6 

**VESPERA  /  ENGINEERING ROADMAP** 

## **6. Target architecture** 

Use a modular monolith. One FastAPI deployment and one PostgreSQL database are enough for the current team size and expected workload. Separate code by domain boundaries so modules can be tested and extracted later only if profiling demonstrates a real scaling need. 



<!-- Start of picture text -->
VESPERA | MODULAR MONOLITH<br>Flutter app | existing Twilight Ul + player<br>[Faseartaplimits,ayerversioned| auth validation,schemas rate J<br>)<br>‘Twilight Orchestrator | one controlled<br>tool-using workflow J<br>Intent compiler Catalog + retrieval Policy + ranker Session planner Ce<br>PostgreSQL (canonical state) | users, tracks, providers, sessions, events, traces, rights, migrations<br><!-- End of picture text -->

### **Domain boundaries** 

|**Module**|**Responsibility**|**Must not do**|
|---|---|---|
|**API / application**|Auth, request validation, orchestration, idempotency,<br>response shaping.|Contain business logic in route functions or expose<br>provider secrets to Flutter.|
|**Intent compiler**|Convert text + mode + context into typed intent, scope,<br>confidence, constraints and ambiguity flags.|Return invented tracks or silently downgrade hard<br>constraints.|
|**Policy engine**|Resolve hard vs soft constraints, conflicts, scopes and<br>unknown metadata behavior.|Use an LLM score as proof of constraint satisfaction.|
|**Catalog / provider**<br>**adapters**|Normalize search, track metadata, provider IDs, previews,<br>deep links and playback capability.|Pretend every provider exposes the same fields or grants<br>streaming rights.|
|**Retrieval / ranking**|Generate candidate pool, apply deterministic filters and<br>calculate candidate scores.|Fetch or fabricate track names directly from the LLM.|
|**Session planner**|Optimize order and trajectory, enforce quotas and replan<br>only unplayed items.|Modify the currently playing track or leak session-only<br>corrections into global taste.|
|**Memory / events**|Persist event evidence; aggregate global, context and<br>session preferences separately.|Treat one skip as a permanent dislike or expose private<br>listening data.|
|**Trace / evaluation**|Record policy version, candidates, scores, decisions,<br>explanation evidence and outcomes.|Generate an explanation unsupported by trace fields.|



INTERNAL BUILD DOCUMENT  •  v1.1  •  7 

**VESPERA  /  ENGINEERING ROADMAP** 

### **Recommended backend layout** 

vespera_backend/ app/ api/v1/ twilight.py sessions.py events.py catalog.py schemas/ intent.py contract.py track.py session.py feedback.py domain/ intent/compiler.py policy/validator.py catalog/normalizer.py retrieval/retriever.py recommendation/ranker.py recommendation/sequencer.py feedback/interpreter.py memory/aggregator.py explanations/provenance.py infrastructure/ database/ providers/ llm/ telemetry/ tests/ main.py 

INTERNAL BUILD DOCUMENT  •  v1.1  •  8 

**VESPERA  /  ENGINEERING ROADMAP** 

## **7. Data foundation: canonical catalog and events** 

### **Canonical Track record** 

Replace the minimal PlaylistItem as the canonical intelligence object. UI cards may still use a small view model, but all internal logic should reference a normalized Track ID and its provider mappings. 

|**Field group**|**Required fields / behavior**|
|---|---|
|**Identity**|vespera_track_id; canonical title; stable artist IDs; album ID; ISRC/MBID when available and verified;<br>duplicate/equivalence links.|
|**Descriptive metadata**|Title, artists, album, duration_ms, release_date, genre/tag taxonomy, language(s), territory/storefront and<br>explicit-content state where supplied.|
|Musical features|No numeric energy/valence is required in Milestone 1. Use only source-provided verified tags/labels. Later<br>derived values must be versioned (e.g. vespera_energy_v1) and include extraction_version, source and<br>confidence. Treat Librosa values as proxies, not ground truth.|
|**Semantic annotations**|Short themes, mood descriptors, instrumentation and narrative tags only from licensed, user-supplied, artist-<br>approved or otherwise permitted sources. Do not use scraped commercial lyrics.|
|Provider mappings|Provider name, provider_track_id, playback_mode, stream/deep-link URLs, playable_ms, preview_asset_ms,<br>session_eligible, license/rights_record_id and verified_at. The planner counts only session_eligible playable_ms.|
|**Rights and provenance**|Asset owner/source, license, permitted processing, permitted territories, expiry/restrictions, metadata source,<br>AI/provenance statement and evidence source.|
|**Quality controls**|Field-level source, confidence, last_updated, verification_status and conflict state. Unknown must remain<br>unknown.|
|Playback capability<br>validation|FULL_LICENSED requires permitted stream URL, verified track license, positive rights_record_id and<br>session_eligible=true; PREVIEW stores preview_asset_ms separately and has session playable_ms=0 unless a<br>specific provider agreement permits session use; HANDOFF counts 0 ms.|



### **Event model** 

ListeningEvent 

event_id                 UUID / idempotency key 

user_id                  server-derived pseudonymous ID from an anonymous device-bound token; never trust a client-supplied user_id session_id               nullable for non-session activity 

track_id                 canonical Vespera track ID 

event_type                impression | start | heartbeat | pause | skip | complete | save | replay | explicit_feedback position_ms               playback position at event time 

duration_ms               observed track duration, if known 

feedback_reason           not_my_taste | wrong_context | too_energetic | too_slow | too_familiar | lyrics | already_heard | other context_id                optional session context occurred_at_utc           server-validated timestamp source_surface             home | twilight | search | queue request_id / trace_id      end-to-end linkage 

INTERNAL BUILD DOCUMENT  •  v1.1  •  9 

**VESPERA  /  ENGINEERING ROADMAP** 

### **Minimum relational schema** 

|**Table**|**Why it exists**|
|---|---|
|users / device_tokens|Server-side pseudonymous user identity and hash of anonymous device-bound API tokens. Events<br>derive user_id from the authenticated token, never from client JSON.|
|**artists / albums / tracks**|Normalized canonical entities.|
|**provider_track_map**|Provider-specific IDs, URLs and playback capabilities.|
|**track_feature**|Feature value, source, confidence and extraction version.|
|**track_annotation**|Tags/themes/language/credits/provenance plus source and license evidence.|
|**listening_event**|Append-only behavioral evidence with idempotency.|
|**taste_profile / taste_evidence**|Aggregated preferences, confidence, recency and evidence lineage.|
|**listening_session /**<br>**session_contract**|Session goal, policy, state, expiry and current queue.|
|**recommendation_trace /**<br>**trace_item**|Candidate set, filters, feature scores, rank, reason codes, policy version and outcome.|
|**data_rights_record**|Rights source, permitted use, territory, expiry and processing restrictions.|



#### **DATA QUALITY RULE** 

A missing audio feature, language tag, artist credit or AI-provenance label is not a negative value. It is unknown. For hard constraints, unknown metadata must be handled explicitly: exclude, ask the user, or label the result as unverified. Never quietly pretend the system knows. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  10 

**VESPERA  /  ENGINEERING ROADMAP** 

## **8. Intent compiler and scope-safe memory** 

### **Memory has four layers** 

|**Layer**|**Stores**|**Update policy**|
|---|---|---|
|**Global taste**|Durable artist/genre/era/audio/theme affinity, replay patterns<br>and explicit long-term preferences.|Update only with explicit “remember this” or repeated,<br>high-confidence evidence. Allow edit and delete.|
|**Context preference**|Preferences that hold in a specific context, e.g. study,<br>workout, commuting or late night.|Update from repeated contextual evidence; keep context<br>label and confidence.|
|**Session state**|Current goal, energy trajectory, current novelty tolerance,<br>temporary exclusions and remaining duration.|May change during this session. Expires at session end<br>unless the user explicitly promotes it.|
|**Raw evidence**|Events, explicit feedback and the recommendation trace that<br>caused the event.|Append-only evidence; derive profiles from it. Never<br>replace evidence with an unexplained model summary.|



### **Intent compiler contract** 

- Input: free text, selected Twilight mode, optional context fields, current session and user-approved memory snippets. 

- Output: strict schema with goal, constraints, soft preferences, exclusions, language, duration, trajectory, discovery budget, memory scope, expiry, confidence and unresolved ambiguity. 

- The parser must preserve negation and scope: “I like this artist, just not when studying” is not a global dislike. 

- Contradictions must be returned explicitly. Example: “no vocals” and “female vocalist only” conflict unless the user clarifies that the second refers to instrumental vocal texture or a separate segment. 

- If a hard constraint cannot be verified from catalog metadata or a permitted provider capability, the system must not claim it has been satisfied. A session planner must budget cumulative playable_ms, not nominal track duration_ms. 

- LLM output is untrusted input. Validate, normalize and reject invalid fields before any tool call. 

### **Scope and expiry policy** 

Instruction: "No sad lyrics tonight" scope = session expires_at = session_end updates_global_taste = false 

Instruction: "I never want this artist recommended again" scope = global_explicit_rule expires_at = null requires_confirmation = true 

Feedback: "Too energetic for studying" scope = study_context + current_session updates_global_taste = false unless repeated evidence crosses a confidence threshold 

### **Agent architecture** 

One orchestrator with a small allow-list of tools is enough. The agent is an execution controller, not a group of role-playing agents. 

- parse_intent(request) -> typed intent draft 

- validate_contract(intent, catalog_capabilities) -> accepted contract + unresolved fields 

- search_catalog(query, filters) -> real canonical track candidates 

- get_taste_context(user_id, scope) -> bounded preference evidence 

- rank_candidates(candidates, contract, taste) -> scored, filtered candidates 

- plan_session(candidates, contract, previous_track) -> ordered queue 

- record_feedback(event) -> state update proposal 

- replan_session(session_id) -> replacement unplayed queue; explain_recommendation(trace_item_id) -> evidence-backed reasons 

INTERNAL BUILD DOCUMENT  •  v1.1  •  11 

**VESPERA  /  ENGINEERING ROADMAP** 

## **9. Retrieval, ranking and session optimization** 

### **Candidate generation** 

For Milestone 1, use PostgreSQL full-text / tag-keyword retrieval only. Add artist-neighborhood and semantic/audio channels later, only when rights and a labelled benchmark support them. Deduplicate by canonical track identity before scoring. 

### **Constraint order** 

1. Resolve and validate the Session Contract. Distinguish hard constraints, soft preferences and target quotas. 

2. Retrieve a broad candidate pool using the available catalog adapters. 

Apply hard constraints using verified fields. Unknown values never count toward a hard quota; they may occupy only an explicitly permitted remainder and must be disclosed as unknown. 

4. Score eligible candidates against taste fit, contextual fit, goal fit, semantic fit and novelty. 

5. Select a sequence satisfying quotas and transition constraints. Do not merely sort a list independently by score. 

6. Generate explanations from saved feature scores and trace evidence, not from free-form model imagination. 

### **A transparent scoring baseline** 

candidate_score = w_taste   * taste_fit 

+ w_goal    * goal_fit 

+ w_context * context_fit 

+ w_semantic* semantic_fit 

- + w_novelty * novelty_fit 

+ w_transition * transition_fit 

- w_repeat  * repetition_penalty 

- w_risk    * metadata_uncertainty_penalty 

Hard constraints are filters, not negative score weights. 

Weights are selected by mode / contract and recorded per trace. 

Do not use arbitrary weights as if they were validated truth. Start with documented defaults, run ablations and tune against human labels and pilot outcomes. Every feature score must be normalized and versioned. 

### **Sequence planner** 

- V1: deterministic greedy look-ahead or beam search over the top candidate pool; enforce max artist repeats, novelty quota and energy trajectory. 

- Optimize a whole sequence, not only per-track relevance. Include transitions such as energy step size, artist repetition, language spread and familiar/adjacent/frontier allocation. 

- Use dynamic quota slack: if the session is behind its novelty or artist-diversity target, the planner may temporarily raise that objective; once the quota is on track, relevance can dominate again. This is a simplified product-level idea inspired by multi-objective sequential optimization research [R5]. 

- Never fabricate numeric “taste match” or “novelty %” values. They must be computed by a documented formula and displayed with their meaning. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  12 

**VESPERA  /  ENGINEERING ROADMAP** 

### **Adaptive queue updates** 



<!-- Start of picture text -->
THE PRODUCT LOOP: PLAN ~ PLAY > LEARN > REPLAN<br>o1 02 03 04 0s 06<br>Intent Contract Plan Play Observe Update<br>— _— — _—> _—<br>What is the<br>listener trying to HardGETSconstraints ewerRetrieve, filter, PreviewTicensed/ owned/ / save,‘kip reason,replay, first;Sessiononlyglobalwithstatetaste<br>‘achieve? OES CE, handoff ‘completion Cheech<br>Replan only the unplayed queue. Keep temporary session<br>corrections out of durable taste memory.<br><!-- End of picture text -->

- Do not update from a single skip alone. Combine reason, position, duration listened, current context and repeated behavior. 

- The first update targets the current session. A global preference update requires explicit user instruction or repeated corroborating events. 

- Replan only unplayed queue items. Persist the previous and new queue version so the change is auditable and reversible. 

- Keep the current track stable unless the user explicitly skips, stops or requests a change. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  13 

**VESPERA  /  ENGINEERING ROADMAP** 

## **10. API and client integration** 

### **Minimal API surface** 

|**Endpoint**|**Purpose**|**Response contract**|
|---|---|---|
|**POST /api/v1/twilight/agent**|Main entry for chat, presets, suggestions, voice<br>transcript and context.|Intent draft, validation status, session/track results,<br>trace IDs and user-facing message.|
|**POST /api/v1/sessions**|Create a session from an accepted Session Contract.|Session ID, contract version, initial queue and plan<br>summary.|
|**GET /api/v1/sessions/{id}**|Read session state and current queue.|Current track, unplayed queue, trajectory, contract and<br>latest plan version.|
|**POST**<br>**/api/v1/sessions/{id}/feedback**|Record skip reason, save, replay, “not now” or natural-<br>language correction.|Accepted event, proposed scope of update, new queue<br>version if replanned.|
|POST /api/v1/events|Ingest playback/search/engagement events not<br>expressed as explicit feedback.|Derive user_id from the anonymous token; reject<br>any client attempt to override the authenticated<br>identity. Return an idempotent acknowledgement.|
|**GET /api/v1/music-dna**|Return measured taste analytics.|Aggregates, sample size, recency window and<br>confidence/coverage.|
|**GET /api/v1/traces/{id}**|Read why a recommendation was selected.|Rank features, filters applied, provenance and<br>explanation evidence.|
|POST<br>/api/v1/auth/anonymous|Bootstrap anonymous install identity.|Issue an opaque device-bound token; store only its<br>hash server-side and return the pseudonymous<br>user ID.|



### **Typed response shape** 

{ "schema_version": "1.0", 

- "request_id": "...", 

- "trace_id": "...", 

"status": "ready | needs_clarification | partial | error", 

"message": "...", 

"intent": { "goal": "deep_focus", "scope": "current_session" }, 

"contract": { "id": "...", "version": 1 }, 

"session": { "id": "...", "plan_version": 1 }, 

"tracks": [ 

{ "track_id": "...", "rank": 1, "playback_mode": "preview", "provider_links": {}, "reason_codes": ["goal_fit", "new_artist"] } ], 

"unverified_constraints": [], 

"next_actions": ["play_preview", "open_provider"] 

} 

### **Flutter integration rules** 

- Create a dedicated TwilightService; keep ApiService as the transport layer and AudioPlayerService as the one playback authority. 

- Use typed Dart request/response models mirroring backend schema versions. Reject or gracefully ignore unknown optional fields; do not cast unvalidated maps throughout widgets. 

- All result cards and player controls use canonical track IDs and the same player state stream/notifier. 

- Use loading, empty, partial and error states. A failed preview lookup must never show a false “Playing” state. 

- Debounce search, cancel stale requests, disable duplicate submits and preserve the user’s input after errors. 

- Keep keys and secrets on the backend. Flutter never receives provider secrets or database credentials. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  14 

**VESPERA  /  ENGINEERING ROADMAP** 

## **11. Master roadmap: the Milestone 1 build path** 

The long-range gates remain the full-product roadmap. Milestone 1 intentionally takes only Gate 0, Gate 1, a minimal Gate 2, Gate 4’s 40-prompt parser slice, Gate 5’s full-text retrieval + trace storage slice, and Gate 6’s greedy planner slice. Minimal event logging and anonymous auth begin before any real session data is accepted. Music DNA, the multilingual benchmark, the full provenance dashboard and the external pilot are deferred. 

### **Gate 0 - Product, rights and repository lock** 

**Outcome:** freeze scope, document provider boundaries and prepare a clean engineering workspace. 

- Lock V1 as discovery + rights-cleared full-length prototype stream + provider handoff, not a general streaming service. Jamendo is the provisional Milestone 1 candidate, subject to its API terms and per-track rights review; iTunes is not the acceptance-session playback source. 

- Mark the existing Twilight UI as frozen; designate Flutter as the production client. 

- Create a development branch and protect main; use small pull requests with tests. 

- Remove or archive generated audit notes and private implementation planning files from the public source tree; never commit secrets or unreviewed AI-generated architecture dumps. 

- Write a provider/right-to-use matrix covering metadata, in-app playback, previews, downloads, AI/audio processing, storage/caching, attribution, territories, expiry and commercial restrictions. Track-level CC terms and API-level terms are separate checks. 

- Create two short ADRs before VSP-003: ADR-001 playback source/capability contract; ADR-002 new-user warm-start and familiarity semantics. 

EXIT GATE 0 / A V1 scope document, provisional Jamendo rights matrix, two ADRs, UI freeze rule, branch/PR workflow and repository hygiene checklist are committed. 

### **Gate 1 - Repair the application skeleton** 

Outcome: the app has one truthful playback state, one real queue and a minimal set of intentional Twilight interactions. 

- Refactor AudioPlayerService to expose current Track, player state, queue, index, duration, position, loading and structured error state. 

- Bind mini-player and Now Playing to that single state source. Delete hard-coded Charlie Puth / Attention state and empty previous/next handlers. 

- Remove dead MusicService and duplicate provider deep-link methods; centralize handoff in provider adapters. 

- Keep Apple/iTunes preview playback out of the player and session planner. In M1, use Apple Search API for catalog lookup and external provider handoff only. If a promotional preview asset is ever shown in a compliant promotional placement, keep it separate from the queue/player and count 0 ms toward session duration. Apply a backend per-IP limiter to Search API requests, cache permitted metadata mappings with verified_at, and back off on 403/429 (honor Retry-After where present). Apple documents approximately 20 Search API calls/minute, subject to change, and says previews are for promoting store content, not entertainment [R18]. 

- Implement queue operations, play/pause/seek/next/previous, player disposal and recoverable failures. 

- Wire typed chat submit and suggestion cards to the same request path. For Milestone 1, the + and microphone controls do not open new sheets or launch voice processing; they show a brief “not available in this milestone” message. Keep Featured on the default mode. Do not implement Music DNA or Mood Journey screens yet. 

EXIT GATE 1 / Player, mini-player and Now Playing share one state source; session duration accounting uses playable_ms; a failed lookup never reports playback. 

### **Gate 2 - Minimal canonical catalog and rights-aware provider** 

**Outcome:** Vespera can reason over normalized tracks independently from where playback occurs. 

- Create canonical Track, Artist, Album, ProviderTrack and DataRightsRecord schemas with migrations. 

- Implement a provider interface: search, get_track, resolve_link, resolve_preview/playback_capability and attribution metadata. 

- Use Jamendo as the provisional Milestone 1 catalog adapter if the developer account and current terms permit the intended non-commercial prototype. Search 50-100 records, use vocalinstrumental=instrumental plus tag filters where available, request licenses/musicinfo, and use the track audio stream only after rights checks. Record attribution and a direct backlink for each item. Do not offer downloads unless audiodownload_allowed is true and the relevant license/terms permit it [R16-R17]. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  15 

**VESPERA  /  ENGINEERING ROADMAP** 

- Use MusicBrainz as an identity/metadata reconciliation source where useful; respect its one-request-per-second guidance and identify the client with a meaningful User-Agent [R14]. 

- Milestone 1 needs 50-100 rights-reviewed tracks, not 200-500. Expand to 200-500 only after the session loop passes. Do not assume the API’s non-commercial grant or a per-track CC license grants commercial use or unrestricted machine analysis. 

- Record field provenance, confidence and rights. Do not scrape commercial lyrics or build on undocumented stream extraction. 

EXIT GATE 2 / 50-100 M1 records have canonical IDs, provider mappings, playback capability, per-track rights evidence, attribution and verification timestamp. 

## **12. Master roadmap: build gates 3-6** 

### **Gate 3 - Minimal event telemetry now; Music DNA later** 

Outcome for Milestone 1: the first authenticated session produces a small, idempotent event log. The analytics screen, learned preference aggregates and full data-deletion workflow are later hardening work, but event capture itself is not deferred. 

- At minimum log session_created, impression, start, heartbeat, pause, complete, skip, save and explicit_feedback. Persist pseudonymous user/session/track IDs, position, event time, reason, source and request/trace IDs. 

- Persist IDs, playback position, context, source and UTC time; make ingestion idempotent and retry-safe. 

- Defer the Music DNA screen and predictive taste model. Keep any demo profile marked synthetic=true; synthetic activity must never be displayed as observed listener history. 

- Add pseudonymous IDs, consent notice, retention policy and user export/delete controls. 

EXIT GATE 3 (M1 slice) / Anonymous token auth and idempotent minimal events work. Music DNA analytics and the DNA screen remain deferred. 

### **Gate 4 - Intent compiler v0 and Recommendation Contract** 

**Outcome:** natural language becomes a validated policy object that the rest of the system can enforce. 

- Create a 40-prompt golden set for Milestone 1. Split it once into 28 tuning prompts and 12 held-out prompts; never tune prompts or rules against the held-out set. Expand toward 150-200 only after the first acceptance loop works. 

- Keep Groq replaceable behind an LLM interface; use deterministic fallback for simple requests and tests. 

- Create a 150-200 prompt golden set covering negation, contradictions, context, temporary/global scope, relative duration and code-mixed language. 

- On the 12 held-out prompts report per-field accuracy and exact critical-field results. Require zero failures on hard-constraint negation and memory-scope classification for this narrow internal gate; report the small sample size and make no broad generalization claim. Ambiguity returns needs_clarification. 

EXIT GATE 4 (M1 slice) / The 40-prompt set is split 28/12; the held-out 12 are untouched during tuning and have zero critical hardconstraint-negation or scope errors. Report the small sample honestly. 

### **Gate 5 - Full-text retrieval, ranking baseline and trace storage** 

**Outcome:** the LLM compiles intent; retrieval and ranking select real candidate records. 

- Start with PostgreSQL full-text and Jamendo tag/keyword filters over title, artist, tags and verified instrumental labels. No vector database, embeddings or cross-modal model in Milestone 1. 

- Create recommendation_trace and trace_item storage in this gate, not Gate 7. Save the candidate snapshot, catalog version, filters, exclusion reasons, score components, rank and plan version so every later explanation and replan can be audited. 

- Use B0 = Jamendo tag/keyword matching (not popularity). Add taste ranking later when sufficient non-synthetic event evidence exists. 

- Treat hard constraints as filters; persist exclusion reasons. Explore adjacent/frontier tracks without replacing relevance with randomness. 

EXIT GATE 5 (M1 slice) / FTS/tag-keyword retrieval is deterministic on a fixed catalog snapshot; recommendation_trace and trace_item persist candidate, filter, score, rank and plan facts. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  16 

**VESPERA  /  ENGINEERING ROADMAP** 

### **Gate 6 - Greedy session planner and feedback replan** 

**Outcome:** Vespera becomes an adaptive session engine rather than a static playlist generator. 

- Plan against playable_ms, and count only records with session_eligible=true and a positive rights decision. For FULL_LICENSED, use the verified playable duration of the permitted stream. For PREVIEW, store preview_asset_ms separately and set session playable_ms=0 unless a provider agreement explicitly authorizes session playback; Apple/iTunes promotional previews are not session-eligible. For HANDOFF, count 0 ms because Vespera cannot verify external playback. The M1 acceptance session must use permitted full-length streams, not previews. 

- Use a deterministic greedy planner for the first milestone. The first 10 minutes use the 3-5 user-selected seed tracks’ artist/tag neighborhood (or already played tracks in that session). Label this as a seed-based familiarity proxy, not proven historical familiarity. Build later tracks from other artists. Treat “not experimental” as a soft tag-based preference unless the catalog has a verified field. 

- Interpret feedback using reason and listening position; “not now” must not become a permanent dislike. 

- Replan only unplayed items and persist prior plan, replacement plan, trigger reason and memory scope. 

EXIT GATE 6 (M1 slice) / A greedy planner produces 30 minutes by playable_ms, respects the instrumental quota and seedneighborhood arc, and replans only unplayed items after reason-coded feedback. 

## **13. Master roadmap: later gates 7-9** 

### **Gate 7 - Recommendation provenance and discovery audit** 

**Outcome:** every surfaced track has an evidence-backed “why this” explanation, and the product can inspect its own discovery patterns. 

- Trace persistence is already required in Gate 5. Gate 7 adds audited provenance views and artist-exposure reports; it does not postpone the trace schema needed for the first build. 

- Generate explanations from trace facts only: “new artist to you”, “within the selected energy range”, “matches study context”, “similar to artists you saved”. 

- Never invent percentages such as 68% taste match unless there is a calibrated, documented score with a userunderstandable definition. 

- Audit artist exposure, artist repeats, catalog popularity bands and long-tail coverage where reliable metadata exists. 

- Show the listener how the current policy shaped results; do not claim “no commercial influence” or “no paid placement” unless the system can verify that claim. 

EXIT GATE 7 / Full provenance views and artist exposure audits are later work; the trace data required to support them already exists from Gate 5. 

### **Gate 8 - India-focused multilingual discovery (deferred beyond Milestone 1)** 

**Outcome:** improve real retrieval and metadata quality for target repertoires, not just translate prompts. 

- Start with English, Hindi, Hinglish/code-mixed Hindi-English and Punjabi. Add other languages only when the catalog and annotators are ready. 

- Support original script, transliteration and common spelling variants as separate searchable forms linked to one canonical artist/track identity. 

- Create human-labelled queries for cross-language intent: theme + negative emotional constraint + musical character + novelty. 

- Measure recall, constraint satisfaction and metadata coverage separately per language and script. Report where the catalog is missing data. 

- Benchmark a multilingual text encoder against PostgreSQL full-text baseline before deployment. CLaMP 3 demonstrates that cross-lingual MIR is an active field, so model use alone is not differentiation [R9]. 

EXIT GATE 8 / Multilingual benchmark is explicitly deferred beyond Milestone 1. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  17 

**VESPERA  /  ENGINEERING ROADMAP** 

### **Gate 9 - Reliability, security and release hardening (pilot deferred)** 

**Outcome:** a stable pilot with observable failures, controlled costs and clear legal/data boundaries. 

- Add unit, API contract, database migration, player widget, integration and end-to-end tests in CI. 

- Add structured JSON logs, request/trace IDs, latency metrics, provider error rates, LLM token/cost tracking and model/prompt versions. 

- Protect endpoints with auth, rate limits, payload limits, timeouts, retry budgets and safe provider fallbacks. 

- Store secrets in backend environment configuration. Rotate any credentials ever committed to the repository. 

- Add consent, delete/export, data retention and incident response instructions before inviting pilot users. 

- Run a small within-subject pilot comparing static and adaptive sessions; do not claim statistical proof from a handful of users. 

EXIT GATE 9 / Public pilot and full release hardening are deferred; a reachable HTTPS demo deployment and anonymous-token security are still required in Milestone 1. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  18 

**VESPERA  /  ENGINEERING ROADMAP** 

## **14. Evaluation plan: prove the engine works** 

Evaluation must be part of development from the first retrieval baseline. A system with a confident UI and no measurement is not an intelligent recommender; it is an untested opinion generator. 

### **Build three datasets** 

|**Dataset**|**Minimum starting scope**|**Required annotations**|
|---|---|---|
|M1 catalog benchmark|50-100 Jamendo tracks; expand only<br>after the full loop passes.|Canonical IDs, artist, provider IDs, audio stream capability,<br>playable_ms, license URL/type, attribution, tags, instrumental label,<br>source and verified_at.|
|M1 intent benchmark|40 prompts: 28 tuning + 12 locked<br>holdout.|Goal, hard/soft constraints, negation, scope, duration, ambiguity and<br>expected clarification.|
|Recommendation<br>judgments|Deferred from Milestone 1; later start<br>with a small labelled slice before 300+<br>judgments.|Relevance, reason, constraint pass/fail, language and novelty. Do<br>not block the first demo on this dataset.|



### **Baselines to compare** 

1. B0 - Jamendo tag/keyword matching baseline using the same catalog snapshot and permitted fields. 

2. B1 - Intent extraction + deterministic filters + text relevance. 

3. B2 - B1 plus taste memory and personalized ranking. 

4. B3 - B2 plus sequence optimization and discovery quotas. 

5. B4 - B3 plus feedback-aware session replanning. 

Use ablation tests to determine which part actually contributes value. If a complex component does not beat the simpler baseline, remove it or redesign it. 

### **Metrics** 

|**Dimension**|**Metrics / definition**|**Guardrail**|
|---|---|---|
|**Intent understanding**|Field-level precision/recall/F1; negation accuracy; scope<br>classification; ambiguity detection.|Report by field and language; do not hide poor<br>performance behind one aggregate accuracy.|
|**Retrieval / ranking**|Precision@K, Recall@K, NDCG@K, HitRate@K on human-labelled<br>candidates.|Only report where relevance labels exist; distinguish offline<br>labels from observed listening behavior.|
|**Policy correctness**|Hard-constraint violation rate; unknown-metadata rate; contract<br>satisfaction; scope-leak rate.|Hard-constraint violation in unit tests must be zero when<br>the field is known. Scope-leak incidents must be zero.|
|**Discovery**|Novel-artist share, intra-list diversity, artist coverage, popularity<br>concentration and language coverage.|Do not maximize novelty blindly; pair it with relevance and<br>user-rated value.|
|**Session outcomes**|Goal-satisfaction rating, session completion, accepted queue<br>changes, skip reason distribution, save/replay.|Treat these as evidence of experience, not as clinical mood<br>or productivity outcomes.|
|**Explanation integrity**|Trace completeness; percentage of displayed reasons supported by<br>trace fields.|Target 100% supported explanations; if data is missing,<br>say “reason unavailable”.|
|**Systems quality**|p50/p95 latency, failure rate, provider success, retry count, LLM<br>calls/tokens and cost per session.|Set performance SLOs after measuring a baseline;<br>separate provider/LLM latency from internal ranker time.|



### **Pilot design** 

- The Milestone 1 build does not include an external listener pilot. Once the core loop passes, run a counterbalanced withinsubject pilot with consent and a pre-registered analysis plan. 

- Collect session-goal satisfaction, perceived control, constraint violations, reasons for skips, perceived discovery quality and trust in explanations. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  19 

**VESPERA  /  ENGINEERING ROADMAP** 

- For a later small pilot (e.g. 15-30 listeners), report descriptive findings and confidence intervals where appropriate. Do not call the result statistically conclusive without a power analysis and larger sample. 

- Record consent, avoid collecting sensitive inferred emotion, and let participants delete their listening data. 

## **15. Catalog rights, privacy and technical guardrails** 

### **Music sourcing rules** 

|**Source / approach**|**V1 treatment**|**Why**|
|---|---|---|
|iTunes Search / 30-second<br>previews|Search/handoff mode only for M1. Do not use<br>previews to fill a 30-minute adaptive session. If a<br>promotional preview is displayed, follow Apple’s<br>store-badge placement/use rules.|Apple states previews are promotional assets, not for<br>entertainment use, and documents approximately 20<br>Search API calls per minute (subject to change)<br>[R18].|
|**Apple Music API / MusicKit**|Use catalog metadata and authorized user-library functions<br>where appropriate. Full-catalog playback requires MusicKit<br>integration, user permission and the relevant Apple Music<br>subscription state [R12].|A catalog API response is not a blanket license to stream<br>arbitrary tracks.|
|**Spotify Platform**|Use only within current platform rules and approved use<br>cases. Do not feed Spotify content into AI models or use it<br>to build analysis/profile features; re-check terms before<br>launch [R11].|The developer terms/policy contain explicit restrictions on AI<br>training and analysis of Spotify content.|
|**YTMusic scraping / YouTube**<br>**search fallback**|Do not make unofficial scraping or stream extraction a<br>production playback foundation. Keep experiments isolated<br>and review official API/terms before any use.|Unofficial endpoints can break and do not establish music<br>playback rights.|
|**MusicBrainz**|Use for identity reconciliation and metadata enrichment,<br>with caching and a meaningful User-Agent; respect the<br>one-request-per-second guideline [R14].|Useful metadata infrastructure, not a streaming or rights<br>grant.|
|Open/licensed/self-owned<br>recordings|Use for test audio only when the recording is self-<br>owned, artist-consented or individually verified<br>under a suitable license. Track the license and<br>allowed uses for every recording.|FMA and Creative Commons make clear that rights<br>differ by track and may restrict commercial use,<br>adaptation or redistribution [R15, R21].|
|Jamendo API / CC catalog|Provisional M1 source for 50-100 full-length<br>prototype streams, only after confirming current API<br>terms and each track’s license. Use<br>instrumental/tag filters, request license/musicinfo<br>fields, credit each artist and Jamendo with a direct<br>backlink, and do not offer downloads unless<br>audiodownload_allowed permits them.|Published API terms state non-commercial API use;<br>commercial use requires contacting Jamendo. Per-<br>track CC terms vary; API terms restrict offline<br>access/caching and require attribution [R16-R17].<br>The published API terms page is dated 17 Sep 2013,<br>so reconfirm before release.|
|**Lyrics**|Defer commercial lyrics analysis until a documented<br>license/permission path exists. Do not scrape or store full<br>lyrics.|Lyrics are copyrighted text; a semantic embedding does not<br>erase the need to check the source license and provider<br>terms.|



### **Privacy rules** 

- Treat listening history, skips, context and preferences as personal data. Minimize collection and explain why each event is needed. 

- Mood and activity are optional, user-declared session context, not a diagnosis. Never market Vespera as a therapist or clinical intervention. 

- Keep the default memory scope narrow. Session-only instructions expire automatically. 

- Build delete/export and consent controls before a public pilot. Establish retention windows for raw event logs and trace payloads. 

- Audit pubspec.yaml for geolocator, pedometer and flutter_tts usage. Remove only dependencies and permissions that are genuinely unused. Keep location collection disabled for M1; do not add location as ambient context without a concrete feature and consent. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  20 

**VESPERA  /  ENGINEERING ROADMAP** 

### **Correcting the old audio-ducking proposal** 

#### **DO NOT BUILD THIS AS A V1 FEATURE** 

The earlier proposal assumes Vespera can intercept and selectively EQ arbitrary audio from other apps. That is not a safe platform assumption. Android playback capture is conditional: source apps must permit capture and satisfy usage/policy requirements; audio focus is the supported mechanism for pausing or ducking playback, not universal access to third-party audio buffers [R13]. Keep system audio-focus behavior in the player reliability scope; defer semantic ducking as a separate OS/audio research project. 

### **Audio feature licensing and naming** 

Audio-feature licensing and naming: do not use numeric energy/valence in Milestone 1. If features are later computed from authorized audio, publish them as versioned proxies (vespera_energy_v1, vespera_valence_v1) with extraction_version, source, confidence and evaluation. Essentia’s library is AGPLv3 for non-commercial applications; its pretrained models are CC BY-NC-ND 4.0 and proprietary licensing is available on request. Do not adopt Essentia models for a commercial path without clearing both model and dependency licenses [R20]. 

## **16. Technology choices and scope control** 

### **Recommended V1 stack** 

|**Layer**|**Use now**|**Defer until evidence requires it**|
|---|---|---|
|**Client**|Flutter (existing app); current Twilight UI; one player service;<br>typed Dart models.|A second React/TanStack production app or a UI<br>rewrite.|
|**Backend**|FastAPI modular monolith; Pydantic schemas;<br>SQLAlchemy/Alembic migrations; structured logging.|Microservices, Kubernetes, service mesh.|
|**Database**|PostgreSQL as canonical persistent store. SQLite may be<br>used for isolated unit tests.|Neo4j or a managed graph platform; sharding.|
|**Search**|PostgreSQL full-text + metadata filters first.|Paid vector DB; external search cluster.|
|**Vectors / ML**|Benchmark local multilingual text embeddings and pgvector<br>only after a text baseline exists. Use Librosa for authorized<br>audio files.|Large custom foundation models or expensive<br>embeddings pipelines before dataset quality is<br>established.|
|**LLM**|Keep Groq behind a provider interface; strict schema<br>validation; deterministic fallback.|Hard dependency on one provider or agent framework.|
|**Cache / jobs**|Simple DB indexes and bounded in-process cache first.|Redis, Celery or queues until load/background<br>processing demonstrates need.|
|**Observability**|JSON logs, request IDs, latency/error metrics, prompt/model<br>versions.|Complex observability stack before core request traces<br>exist.|



### **Zero-cost prototype discipline** 

- Local development, Docker Compose, PostgreSQL and open-source libraries are sufficient to prove the core loop. A phone demo additionally requires a publicly reachable HTTPS backend; local Compose alone is not deployable to a physical device outside the development network. 

- A free hosted LLM tier may be used only as an optional development adapter; quotas and terms can change. Read GROQ_MODEL from environment configuration, validate the chosen model against Groq’s current model list during setup/release, and keep a deterministic fallback. Never list models on each user request. 

- No paid vector service, commercial lyrics provider, licensed commercial catalog, CDN, P2P network or GPU-hosted inference is required for the first proof. Jamendo is non-commercial prototype-only unless a separate commercial/API agreement is secured. 

- Do not make “$0” an architectural requirement for a future commercial product. It is a prototyping constraint, not a scalability strategy. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  21 

**VESPERA  /  ENGINEERING ROADMAP** 

### **Features to defer or remove from the core roadmap** 

|**Idea from the earlier concept list**|**Decision**|**Reason**|
|---|---|---|
|**Hum-to-search**|Defer as optional utility.|Useful but commoditized; needs an authorized reference catalog and robust audio<br>matching.|
|**Lyrics display / semantic lyric**<br>**search**|Defer until licensed data<br>exists.|The core recommender does not depend on full lyric text.|
|**AI music therapist**|Remove the claim; keep a<br>user-directed Mood Journey<br>only.|No clinical evidence or clinical system. Avoid health claims.|
|**AI copyright / royalty tools**|Separate creator-rights and<br>business products.|Copyright similarity is not a legal infringement finding; royalty analysis needs rights-<br>holder/distributor statements and contractual data access.|
|**AI mixing/mastering and 6-stem**<br>**DAW**|Separate product/research<br>project.|Different problem domain, audio rights and engineering stack.|
|**P2P streaming mesh**|Remove from V1 and V2.|No scale justification; adds licensing, abuse, NAT traversal, integrity and reliability<br>problems.|
|**Social co-listening / trivia**|Later growth experiment.|Does not strengthen the core recommendation loop.|
|**Semantic ducking / spatial audio**|Separate OS/audio<br>research project; 3D visuals<br>remain optional.|Third-party audio capture is conditional; spatial effects do not prove recommendation<br>quality.|



## **17. Implementation tickets and the first milestone** 

Create these as GitHub issues and execute them in dependency order. Estimates below are focused engineering days for one developer, not calendar promises; external provider approval, debugging on physical devices and free-tier host availability can extend elapsed time. 

|**Ticket**|**Work item**|**Definition of done**|
|---|---|---|
|VSP-001 (0.5-<br>1d)|Create ADRs and V1 scope lock.|ADR-001 playback source/capability; ADR-002 warm-start/familiarity;<br>provisional Jamendo non-commercial scope; Flutter-only/UI-freeze<br>decision.|
|VSP-002 (0.5-<br>1d)|Create branch, CI baseline and backend test<br>harness.|Lint, type checks and unit tests run on PR; secrets are absent; audit<br>geolocator/pedometer/flutter_tts and remove only unused dependencies.|
|VSP-003 (1-<br>1.5d)|Create canonical Track, ProviderTrack and<br>DataRightsRecord models.|ProviderTrack carries provider, provider_track_id, playback_mode,<br>audio_url/deep_link, playable_ms, license and verified_at; validators<br>enforce capability fields.|
|VSP-004 (2-<br>3d)|Refactor AudioPlayerService as one source<br>of truth.|Current track, provider capability, queue, state, actual position, playable<br>duration, loading and structured errors are observable.|
|VSP-005 (1-<br>2d)|Connect mini-player and Now Playing.|Both screens render from one player state; hard-coded track removed;<br>next/previous work; preview cannot be misrepresented as a full session<br>track.|
|VSP-006 (1-<br>2d)|Centralize provider adapters and Apple<br>handoff.|Jamendo stream adapter validates rights/attribution; Apple catalog search +<br>external handoff only; no Apple promotional preview playback; backend Search<br>API rate limit and 403/429 backoff work.|
|VSP-007 (1-<br>2d)|Add PostgreSQL, migrations, anonymous<br>token auth and minimal events.|Bootstrap endpoint issues opaque device-bound token; hash stored server-<br>side; user_id is token-derived; events are idempotent and persisted.|
|VSP-008 (1-<br>2d)|Seed the M1 Jamendo test catalog.|50-100 tracks with per-track CC/API rights review, playable_ms,<br>instrumental/tags, attribution, direct backlink and verified_at; no<br>unsupported audio-feature claims.|
|VSP-009 (1-<br>1.5d)|Implement Twilight typed request/response<br>models and service.|Flutter attaches the anonymous token; user identity is not trusted from<br>JSON; suggestions and typed chat share one endpoint; errors/loading<br>work.|



INTERNAL BUILD DOCUMENT  •  v1.1  •  22 

**VESPERA  /  ENGINEERING ROADMAP** 

|**Ticket**|**Work item**|**Definition of done**|
|---|---|---|
|VSP-010 (1.5-<br>2d)|Implement intent compiler v0 with 40-prompt<br>golden set.|28 prompts for tuning, 12 locked holdout; GROQ_MODEL comes from<br>environment; setup/release verifies the selected model remains available.|
|VSP-011 (2-<br>3d)|Implement PostgreSQL FTS/tag retrieval,<br>deterministic filters and trace persistence.|B0 is tag/keyword match; no vectors; every candidate, filter, exclusion,<br>score, rank and plan version is stored in recommendation_trace.|
|VSP-012 (2-<br>3d)|Build greedy planner, seed-based warm<br>start and feedback endpoint.|Planner sums playable_ms; 3-5 seed picks drive first 10 minutes; 80%<br>verified instrumental playable time; skip reason replans only unplayed<br>queue.|
|VSP-013 (1-<br>1.5d)|Deploy the FastAPI backend to a publicly<br>reachable HTTPS free-tier target for the<br>phone demo.|Health check and CORS work; secrets are configured in host env; Flutter<br>base URL is supplied via --dart-define=VESPERA_API_BASE_URL;<br>physical-device test passes.|



### **First working demo - revised acceptance scenario** 

###### User prompt: 

“Build 30 minutes of calm study music using permitted full-length Jamendo streams. At least 80% of total planned playable time must be verified instrumental. Use a seed-based opening for the first 10 minutes, then introduce artists outside the seed neighborhood. Avoid explicitly tagged experimental material, but do not claim an experimentalness guarantee where metadata is missing.” 

###### Expected system behavior: 

1. Parse goal, duration, verified instrumental quota, seed-based opening rule and soft novelty/experimentalness preferences. 

2. Display the contract-summary bottom sheet. Within that same sheet, let the user select 3-5 seed tracks; this is the only seed-selection surface. 

3. Retrieve Jamendo candidates with full-stream capability and per-track rights/attribution evidence. Do not use iTunes preview results in this queue. 

4. Enforce at least 80% verified instrumental playable milliseconds; unknown labels never count as instrumental. If the catalog cannot satisfy the quota, return a visible unsatisfied-contract result instead of silently relaxing it. 

5. Sum playable_ms until the planned queue covers 30 minutes. Seed-neighborhood tracks cover the first 10 minutes; later tracks introduce artists outside that neighborhood. 

6. Show trace-backed reasons for each recommendation. 

7. User skips one track and selects a reason in the skip-reason sheet (for example, “too energetic”). 

8. Replan only the unplayed queue with the reason scoped to this session; preserve the currently playing track and global taste profile. 

9. The demo profile is persisted with synthetic=true; no fabricated history is shown as real Music DNA. 

MILESTONE 1 EXIT / From a physical phone, a new anonymous install creates a 30-minute session over 50-100 rights-reviewed Jamendo tracks. The queue sums playable_ms, satisfies an 80% verified-instrumental time quota, uses 3-5 user-selected seed tracks as a clearly labelled familiarity proxy for the opening 10 minutes, explains selections from stored traces, and changes only the unplayed queue after a reason-coded skip. The backend is reachable over HTTPS. No iTunes preview is used to fake session duration. 

## **18. Engineering operating rules** 

### **Definition of done for every feature** 

- The user story has a measurable behavior and a clear failure state. 

- API and data models are versioned; model outputs are validated; migrations are tested. 

- Tests cover happy path, empty catalog, missing metadata, provider timeout, LLM timeout, duplicate event and contradictory intent. 

- Logs and recommendation traces can explain what happened without logging unnecessary personal content. 

- UI reports real state, not optimistic/fake state. Every visible button has an intentional action. 

- Feature is measured against a baseline before it is called an improvement. 

- Data source and rights are documented before the source is used in processing, storage, training or playback. 

### **Change-control rules** 

- Any new feature request must identify which core problem it solves, what dependency it needs and what milestone it delays. 

- No new database, model provider or infrastructure service without a measured reason and an ADR. 

- No new “agent” unless a separate agent has independent permissions, state, evaluation and clear need. Default is one orchestrator with deterministic tools. 

- No feature should be described as AI-powered unless the system uses a model or ML method whose input, output and evaluation are known. Every nontrivial recommendation change must keep a baseline and an experiment record. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  23 

**VESPERA  /  ENGINEERING ROADMAP** 

### **Risks to review every release** 

|**Risk**|**Control**|
|---|---|
|**Catalog/license violation**|Rights record, provider terms review, asset-level permission and restricted-use flags.|
|**Hallucinated track or**<br>**explanation**|LLM cannot output final catalog IDs; explanations must be generated from persisted traces.|
|**Preference memory**<br>**contamination**|Separate global/context/session scope; TTL; explicit promotion; user edit/delete.|
|**Popularity lock-in**|Track artist exposure and discovery share; evaluate relevance and long-tail exposure together.|
|**Biased or missing metadata**|Per-field provenance/confidence; per-language coverage; unknown remains unknown.|
|**API cost/latency spike**|Request budget, timeouts, retries, caching, LLM-call limits and deterministic fallback.|
|**Fake playback/UI state**|Single player state source; integration test on every screen.|
|**Sensitive mood inference**|Use user-declared context only; no health claims, facial analysis or hidden emotion inference.|



INTERNAL BUILD DOCUMENT  •  v1.1  •  24 

**VESPERA  /  ENGINEERING ROADMAP** 

## **19. Decisions to lock now** 

|**Decision**|**Recommended lock**|**Revisit trigger**|
|---|---|---|
|**Product category**|Adaptive music intelligence / discovery; not a licensed streaming<br>service in V1.|A lawful catalog licensing agreement and product-<br>market evidence.|
|**Production client**|Flutter only. Keep current Twilight visual shell.|A documented business case for another client.|
|**Backend topology**|FastAPI modular monolith.|Measured load, release independence or team<br>boundaries that justify extraction.|
|**Primary database**|PostgreSQL.|Measured operational constraint; not preference<br>for a fashionable tool.|
|**Vector search**|Not required for the first baseline. Benchmark after FTS.|Embedding retrieval materially improves<br>recall/latency on labelled queries.|
|**Agent count**|One orchestrator; typed tools.|A real authorization/state boundary that requires<br>an independent agent.|
|Playback|Jamendo full-length stream for M1 only after per-track CC +<br>current API terms review; Apple catalog search and external<br>handoff only. Any Apple promotional preview is not session<br>playback; external handoff contributes 0 in-app duration.|Written playback/API rights and per-track<br>license evidence; commercial use requires<br>separate provider agreements.|
|**Lyrics**|No scraping or full commercial lyric storage.|Verified license and legal review for text<br>processing and display.|
|**AI provenance**|Use evidence-backed metadata; unknown is an acceptable<br>value.|Reliable provider/artist verification source or<br>validated provenance pipeline.|
|**Mood journey**|User-directed session trajectory, not therapy.|Only revise claims after appropriate evidence and<br>policy review.|



### **What to publish publicly** 

- A clear README describing what currently works, what is experimental and what requires third-party authorization. 

- An architecture diagram and an honest feature status table. 

- A reproducible evaluation report with dataset provenance, baselines, metrics and limitations. 

- A short demo of the end-to-end acceptance scenario, including a feedback-triggered replan. 

- Do not publish private audit files, secrets, unlicensed datasets or user listening histories. 

#### **FINAL RULE** 

Do not measure progress by the number of AI features visible on the screen. Measure it by how correctly Vespera interprets, enforces, explains and adapts to the listener’s intent. 

INTERNAL BUILD DOCUMENT  •  v1.1  •  25 

**VESPERA  /  ENGINEERING ROADMAP** 

## **20. Research and technical references** 

_Sources reviewed for this roadmap. Product pages, API terms, model availability and provider policies can change; re-check the linked terms before every public or commercial release. Accessed 14 November 2026._ 

**[R1] Spotify Prompted Playlist in beta (22 Jan 2026).** Official product announcement: natural-language prompts, personalization, user steering and refresh behavior. Open source 

**[R2] YouTube Music: Press play on these new YouTube Music updates (23 Sep 2026).** Official announcement of Ask Music, conversational discovery and queue/artist exploration. Open source 

**[R3] Fazelnia et al., Textual User Taste: Natural-Language User Context for Foundation-Model Recommender System at Scale (3 Nov 2026).** Spotify Research / RecSys CARS workshop publication. Reports scale deployment and limitations in negation and short-term temporal adaptation. Open source 

**[R4] Tsukuda et al., Exploring the effectiveness of user-driven intent-based recommendation models implemented in a realworld music web service (16 Jul 2025).** Multimedia Tools and Applications. Study of 1,116 intent-based models created by 417 users on Kiite. Open source 

**[R5] Moor et al., Stochastic Primal-Dual Decoding for Multiobjective Generative Recommender Systems (KDD 2026, 7 Aug 2026).** Spotify Research. Inference-time dynamic balancing of relevance and auxiliary objectives in sequential recommendations. Open 

##### <u>source</u> 

**[R6] Beyond Skipping: Understanding User Intent in Music Recommendation (Zenodo record, 20 Aug 2026).** Supplementarymaterial record. Treat as preliminary supporting material; author metadata is anonymous in the record. Open source 

**[R7] Porcaro et al., Surfacing Problematic Recommender System Behaviors Affecting Music Discoverability (CHI 2026).** Thinkaloud protocol with 20 Italian digital-native listeners; user perceptions of narrow niches, commercial imperatives and discoverability. Open 

##### <u>source</u> 

**[R8] Valk and Izyumenko, 2026 music metadata articles in Journal of Intellectual Property Law & Practice.** Discussion of metadata interoperability, identifiers, language/territory tags, GenAI attribution and cultural visibility. Open source 

**[R9] Wu et al., CLaMP 3: Universal Music Information Retrieval Across Unaligned Modalities and Unseen Languages (Findings of ACL 2025).** Cross-modal and cross-lingual music retrieval research; useful benchmark context, not a Vespera-owned novelty claim. Open source 

**[R10] Fernandes and Vlassis, The sound of fairness: AI and recommender systems in the European music industry (Frontiers in Communication, 2026).** 22 interviews and 360 survey responses; the transparency item with 81.9% “not at all transparent” was answered by n=264. Open source 

**[R11] Spotify Developer Terms and Developer Policy.** Current platform restrictions, including restrictions on AI training and analysis of Spotify content. Review the live terms before integration. Open source 

**[R12] Apple Music API and MusicKit.** Official catalog API, user authorization and subscription-aware playback integration documentation. 

##### <u>Open source</u> 

**[R13] Android Developers: Manage audio focus; AudioPlaybackCaptureConfiguration.** Official platform guidance for focus, ducking and conditional playback capture. Open source 

**[R14] MusicBrainz API and rate limiting.** Official Web Service guidance, including the one-request-per-second application limit and UserAgent requirement. Open source 

**[R15] Free Music Archive License Guide and Terms.** Per-track license rules; do not assume all downloadable recordings are unrestricted. Open source 

[R16] Jamendo API Terms of Use. Published API terms describe non-commercial API use, individual Creative Commons licenses, attribution/backlink requirements, cache/offline restrictions and contacting Jamendo for commercial use. The published page states last modified 17 September 2013; reconfirm current terms in writing before release. https://devportal.jamendo.com/api_terms_of_use 

[R17] Jamendo API v3.0 tracks method and developer documentation. Documents vocalinstrumental and tag filters, audio and audiodownload fields, per-track license/musicinfo includes and audiodownload_allowed. https://developer.jamendo.com/v3.0/tracks 

[R18] Apple Services Performance Partners, iTunes Search API. Apple documents approximately 20 Search API calls per minute (subject to change), recommends caching for larger sites and says promotional previews are only for promoting store content, not entertainment use, with store-badge placement requirements. https://performance-partners.apple.com/search-api 

[R19] GroqDocs, Model Deprecation and Supported Models. llama3-8b-8192 was retired on 30 August 2025; the Models API lists currently available IDs. Use an environment-selected, regression-tested production model. https://console.groq.com/docs/deprecations and https://console.groq.com/docs/models 

INTERNAL BUILD DOCUMENT  •  v1.1  •  26 

**VESPERA  /  ENGINEERING ROADMAP** 

[R20] Essentia Licensing Information. Essentia library is AGPLv3 for non-commercial applications; MTG pretrained models are CC BY-NC-ND 4.0 for non-commercial use, with proprietary licenses available on request. https://essentia.upf.edu/licensing_information.html 

[R21] Creative Commons license overview. License terms differ on commercial use, derivatives, share-alike and attribution; evaluate the specific license on each track instead of treating all CC works alike. https://creativecommons.org/cc-licenses/ 

## **APPENDIX A. VERSION 1.1 IMPLEMENTATION CORRECTIONS** 

This appendix makes the first release runnable. It overrides conflicting Milestone 1 details elsewhere in v1.0. Long-range gates remain valid, but features explicitly marked deferred below must not block the first acceptance build. 

### **A1. Playback capability is a first-class contract** 

A track’s nominal duration is not proof that Vespera can play that much audio. ProviderTrack must express what Vespera can legally and technically deliver. The session planner adds playable_ms only. duration_ms remains descriptive catalog metadata and must never be used to fill a session clock. 

from datetime import datetime from enum import Enum from pydantic import BaseModel, Field, model_validator class PlaybackMode(str, Enum): FULL_LICENSED = "full_licensed" PREVIEW = "preview" HANDOFF = "handoff" class ProviderTrack(BaseModel): provider: str provider_track_id: str playback_mode: PlaybackMode audio_url: str | None = None deep_link: str | None = None playable_ms: int = Field(ge=0) license: str | None = None verified_at: datetime @model_validator(mode="after") def validate_capability(self): if self.playback_mode is PlaybackMode.FULL_LICENSED: if not self.audio_url or not self.license: raise ValueError("FULL_LICENSED requires audio_url and license") if self.playback_mode is PlaybackMode.PREVIEW and self.playable_ms <= 0: raise ValueError("PREVIEW requires a positive preview window") if self.playback_mode is PlaybackMode.HANDOFF and not self.deep_link: raise ValueError("HANDOFF requires deep_link") if self.playback_mode is PlaybackMode.HANDOFF and self.playable_ms != 0: raise ValueError("HANDOFF is not in-app playable duration") return self 

The schema validator is necessary but not sufficient: FULL_LICENSED also requires a positive rights decision referenced by rights_record_id. The provider’s API/application permission, the specific track license, permitted territory, attribution duty, allowed processing, stream delivery, storage/cache limits and any expiry must all pass independently. A string in the license field is not a legal review. PREVIEW is not automatically session-eligible; Apple/iTunes promotional previews have playable_ms=0 for the planner and are never a substitute for a licensed stream. 

### **A2. Jamendo is the provisional Milestone 1 catalog, not an automatic commercial** 

### **source** 

Jamendo’s track API documents vocalinstrumental=instrumental and tag filters, and can return license/musicinfo fields plus audio and audiodownload URLs. It also exposes audiodownload_allowed; do not surface a download option when that flag is 

INTERNAL BUILD DOCUMENT  •  v1.1  •  27 

**VESPERA  /  ENGINEERING ROADMAP** 

false. The `audio` stream and the `audiodownload` link are different capabilities. M1 should stream only after the API-level and per-track rights checks pass. [R17] 

The published Jamendo API terms state that API use is free for non-commercial use, commercial use requires contacting Jamendo, content carries individual Creative Commons licenses, applications must credit the artist and Jamendo with a direct backlink, and the application cannot be designed for offline access or broad content caching. The published API terms page is dated 17 September 2013; get written confirmation of current terms before public distribution or any commercial plan. [R16] 

Do not infer that a track’s CC license grants unrestricted commercial use, derivative works, offline storage or machine-learning use. Record the exact per-track license URL/type. For M1, avoid audio-model training and large-scale content retention; use Jamendo’s supplied instrumental/tag metadata to validate the first constraint. If future feature extraction or embeddings are planned, obtain clarity on the content-processing rights first. 

### **A3. Cold-start warm-up is a seed-based proxy** 

A new listener has no listening history. The contract-summary bottom sheet therefore includes the only seed-selection control permitted in M1: the user selects 3-5 tracks from the 50-100-track catalog. For the first 10 minutes, the planner prefers tracks sharing an artist or verified tag neighborhood with those seeds. After that, it introduces artists outside the seed neighborhood. This is a seed-neighbor proxy, not proof that the listener has previously heard or liked those tracks. Label it honestly in the UI and trace. 

A demo profile that contains generated or scripted events must carry synthetic=true in the profile and event evidence. Music DNA is deferred; when it is later introduced, synthetic evidence must be excluded from real-listener analytics or displayed with a conspicuous demo label. 

### **A4. UI freeze: exactly two new surfaces in Milestone 1** 

Surface 1 is the contract-summary bottom sheet, which also hosts the 3-5 seed-track picker. Surface 2 is the skip-reason sheet. Both should reuse existing Twilight glass/neumorphic components, colors and typography. Do not create a separate seedpicker surface. 

Defer the + Add Context sheet, microphone/voice flow, Featured dropdown, Music DNA screen and Mood Journey screen. The + and microphone controls can show a brief non-modal availability message; the Music DNA card can report that listening data is not available yet; the semantic-search card and suggestion cards should prefill the existing text field and share the same submit endpoint. The base Twilight layout remains pixel-frozen. 

### **A5. Milestone 1 cut line** 

|**Gate / workstream**|**Included in Milestone 1**|**Explicitly deferred**|
|---|---|---|
|Gate 0 - scope and rights|Scope lock, two ADRs, repository hygiene,<br>provider/right-to-use matrix, branch and PR<br>workflow.|Commercial licensing, broader provider<br>portfolio.|
|Gate 1 - app skeleton|One real player state, queue,<br>mini-player/Now Playing integration,<br>structured errors, typed Twilight request and<br>suggestion path.|Voice, Add Context sheet, new major<br>screens.|
|Gate 2 - minimal catalog|50-100 Jamendo tracks with verified per-<br>track rights, attribution, playback capability<br>and playable_ms.|200-500+ catalog expansion; lyrics<br>ingestion; commercial catalog.|
|Gate 3 - telemetry slice|Anonymous device-bound auth and minimal<br>idempotent play/skip/completion/feedback<br>event log from first live session.|Music DNA aggregates and screen;<br>predictive taste model.|
|Gate 4 - intent v0|40 prompts split 28 tuning / 12 held-out;<br>structured output; negation, hard constraints<br>and memory scope validation.|150-200 prompt benchmark and multilingual<br>benchmark.|
|Gate 5 - retrieval + trace|PostgreSQL FTS/tag-keyword retrieval,<br>deterministic filters, B0 baseline,<br>recommendation_trace persistence.|Vector DB, embeddings, cross-modal<br>retrieval, artist fairness dashboard.|
|Gate 6 - planner + feedback|Greedy planner, playable_ms accounting, 3-<br>5 seed-track warm start, reason-coded skip<br>and replan of unplayed queue.|Beam search, contextual bandits, complex<br>sequencing models.|
|Gate 7-9|Only minimal trace schema and basic<br>release security needed for the phone<br>demo.|Full provenance/artist-exposure views,<br>multilingual benchmark, 15-30 person pilot<br>and broad release hardening.|



INTERNAL BUILD DOCUMENT  •  v1.1  •  28 

**VESPERA  /  ENGINEERING ROADMAP** 

The M1 cut line is deliberately narrow. Do not add Music DNA, Gate 8 multilingual retrieval, a 300-judgment dataset or the 1530 person pilot until the end-to-end session passes on a physical phone. 

### **A6. Two-week foundation sequence and effort estimates** 

The first two weeks are reserved for VSP-001 through VSP-006 plus the 50-100-track VSP-008 seed-catalog work. VSP-008 may run in parallel with the player/provider tasks once the Jamendo rights checklist and canonical schema are settled. Based on one developer, the expected focused effort is approximately 7-12 engineering days. That range excludes external account approval, provider clarification and unexpected device/player integration defects. 

|**Order**|**Work**|**Estimate**|**Exit condition**|
|---|---|---|---|
|Days 1-2|VSP-001 / ADR-001 and<br>ADR-002; VSP-002 branch, CI<br>and test harness.|1-2 days|Decisions committed; CI runs;<br>no secrets.|
|Days 2-4|VSP-003 canonical Track /<br>ProviderTrack /<br>DataRightsRecord schemas.|1-1.5 days|Capability validator and model<br>tests pass.|
|Days 4-7|VSP-004 AudioPlayerService<br>and VSP-005 screen state<br>wiring.|3-5 days|Real queue, current item,<br>position, errors and controls<br>work in Flutter.|
|Days 7-9|VSP-006 provider adapter:<br>Jamendo candidate stream +<br>Apple handoff/search boundary.|1-2 days|Rights-aware provider<br>capabilities; lazy Apple preview<br>resolution and rate-limit<br>handling.|
|Days 8-10|VSP-008 seed 50-100 Jamendo<br>tracks; track-by-track rights and<br>metadata checks.|1-2 days|Seed catalog is reproducible<br>and has no unverified<br>FULL_LICENSED record.|



After the foundation sprint, VSP-007 through VSP-013 implement anonymous event capture, typed Twilight service, the 40prompt intent compiler, FTS + trace storage, greedy session planning and public HTTPS deployment. A realistic one-developer estimate for the remainder is another 8-13 focused days, plus hosting/provider setup and QA. Treat this as an engineering estimate, not a promised calendar deadline. 

### **A7. The missing deployment and identity requirements** 

VSP-007 owns anonymous authentication as well as event persistence. A first-run endpoint issues a cryptographically random opaque token bound to that app installation. Store only a token hash server-side; return a pseudonymous user ID; persist the token in platform secure storage. The backend derives user_id from the token for every event and rejects caller-supplied user IDs. Do not use a static hardware identifier as an authentication secret. 

VSP-009 attaches this token to Twilight requests. VSP-013 deploys FastAPI to a publicly reachable HTTPS host and supplies the URL to Flutter through --dart-define=VESPERA_API_BASE_URL. Include /health, production CORS allow-list, server-side provider secrets and a physical-device smoke test. Free-tier sleep/cold-start and quota behavior must be tested; a free tier is a prototype convenience, not a production availability commitment. 

### **A8. Provider, model and feature-processing constraints verified for v1.1** 

|**Item**|**Verified fact**|**Roadmap consequence**|
|---|---|---|
|Jamendo API|The tracks endpoint documents<br>instrumental/vocal and tag filters,<br>license/musicinfo includes, audio vs<br>download URLs, and<br>audiodownload_allowed [R17].|Provisional non-commercial M1 stream<br>source. Record each track license; attribute<br>artist + Jamendo; direct-link each item; do<br>not download or cache offline.|
|Jamendo terms|Published API terms say non-commercial<br>API use is free, commercial use requires<br>contacting Jamendo, require<br>credits/backlinks and restrict caching/offline<br>access [R16]. Terms page last modified 17<br>Sep 2013.|Reconfirm current terms in writing before<br>public release; do not treat prototype access<br>as commercial clearance.|
|Apple iTunes Search|Apple documents ~20 calls/minute, subject<br>to change; recommends caching for large<br>sites; previews are promotional, not for<br>entertainment [R18].|Use Apple Search API for metadata lookup<br>only, rate-limit at the backend, cache only as<br>allowed by Apple terms, and back off on<br>403/429. Do not play iTunes promotional<br>previews as session audio.|



INTERNAL BUILD DOCUMENT  •  v1.1  •  29 

**VESPERA  /  ENGINEERING ROADMAP** 

|**Item**|**Verified fact**|**Roadmap consequence**|
|---|---|---|
|Groq model config|Groq retired llama3-8b-8192 on 30 Aug<br>2025; current model IDs are exposed by the<br>Models API [R19].|Remove hard-coded retired ID; use<br>GROQ_MODEL env var and validate<br>chosen model during setup/release.|
|Essentia|Library is AGPLv3 for non-commercial<br>applications; pretrained MTG models are CC<br>BY-NC-ND 4.0, proprietary license by<br>request [R20].|Do not assume commercial-safe. Avoid<br>Essentia models in M1; clear model and<br>dependency licenses before product use.|
|Derived audio features|Librosa/Essentia outputs are computed<br>estimates, not ground-truth Spotify-style<br>attributes.|Store only as vespera_energy_v1 etc. with<br>extraction_version, source and confidence.<br>No numeric energy claims in M1.|



### **A9. Milestone 1 hard acceptance checks** 

|**Check**|**Pass condition**|
|---|---|
|Rights|Every queued full stream has a rights record, source terms version,<br>per-track license, allowed use, attribution and verified_at. Unknown<br>rights means no playback.|
|Duration|Apple/iTunes promotional preview contributes 0 ms to session duration<br>and cannot be used to satisfy this acceptance scenario.|
|Instrumental quota|At least 80% of planned playable milliseconds carry a verified<br>instrumental label from an approved metadata source. Unknown<br>labels do not count toward the numerator.|
|Warm start|The first 600,000 ms are drawn from the selected seed artists/tag<br>neighborhood or items already played in the current session. The UI<br>calls this a seed-based proxy, not a known-history claim.|
|Novelty arc|After the 10-minute boundary, the planner introduces artists outside<br>the seed neighborhood when eligible candidates exist; insufficient<br>catalog coverage is surfaced, not silently fabricated.|
|Feedback loop|A skip reason is recorded; only the unplayed queue is replanned;<br>currently playing item and global profile remain unchanged.|
|Traceability|Every returned item has a persisted candidate/filter/score/rank/plan<br>trace. Displayed explanations must be regenerated from that trace.|
|Deployment|The app runs on a physical device against public HTTPS; the<br>backend derives user_id from an anonymous token; no provider<br>secret is in Flutter.|



### **A10. Definition of what Milestone 1 does not prove** 

Passing the M1 demo does not prove commercial rights, platform-scale availability, personalized familiarity from real long-term history, calibrated audio emotion recognition, multilingual retrieval quality, superiority to Spotify or YouTube Music, or statistically significant listener satisfaction. It proves a narrower engineering claim: a rights-aware, user-steered session can be compiled, scheduled using playable capability, checked against verified constraints, and adapted from reason-coded feedback. 

_Treat the roadmap as the controlling plan. When new research appears, update the evidence and decision register; do not add a feature automatically. When a milestone passes, record the commit/PR, tests, measured result and known limitation. The roadmap should evolve through evidence, not enthusiasm._ 

INTERNAL BUILD DOCUMENT  •  v1.1  •  30 

