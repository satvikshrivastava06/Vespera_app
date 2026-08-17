import { createFileRoute } from "@tanstack/react-router";
import { ChevronDown, ArrowUpRight, Plus, Mic, Globe, Search, AudioLines } from "lucide-react";
import orb from "@/assets/energy-orb.png";
import logo from "@/assets/twilight-logo.png";
import aurora from "@/assets/aurora-streaks.jpg";

export const Route = createFileRoute("/")({
  head: () => ({
    meta: [
      { title: "Twilight AI" },
      { name: "description", content: "Twilight AI — your personal AI music companion." },
    ],
  }),
  component: Index,
});

function Index() {
  return (
    <div className="min-h-screen bg-app flex justify-center">
      <div className="w-full max-w-[440px] px-6 pt-10 pb-6 flex flex-col">
        {/* Header */}
        <header className="flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <img src={logo} alt="Twilight AI" width={36} height={36} className="h-9 w-9 object-contain" />
            <span className="text-[22px] font-bold tracking-tight">Twilight AI</span>
          </div>
          <button className="glass-pill rounded-full px-5 py-2.5 text-sm font-medium">
            Vespera
          </button>
        </header>

        {/* Featured pill */}
        <div className="mt-7 flex justify-center">
          <button className="glass-pill rounded-full px-5 py-2.5 flex items-center gap-2 text-sm font-medium">
            Featured
            <ChevronDown className="h-4 w-4" />
          </button>
        </div>

        {/* Orb */}
        <div className="mt-6 flex justify-center">
          <img
            src={orb}
            alt=""
            width={280}
            height={280}
            className="h-[280px] w-[280px] object-contain orb-glow"
          />
        </div>

        {/* Greeting */}
        <div className="mt-4 text-center">
          <h1 className="text-[34px] font-bold leading-tight">Good day!</h1>
          <p className="mt-2 text-[15px] text-white/55">How may i assist you today?</p>
        </div>

        {/* Featured card with aurora streaks */}
        <div className="mt-7 rounded-[28px] p-[1px] bg-gradient-to-b from-white/15 to-white/[0.04]">
          <div className="rounded-[27px] relative overflow-hidden bg-[#0d0a1f]/70 backdrop-blur-xl">
            <img
              src={aurora}
              alt=""
              aria-hidden
              className="absolute inset-0 w-full h-full object-cover opacity-70 mix-blend-screen pointer-events-none"
            />
            <div className="absolute inset-0 bg-gradient-to-r from-[#0d0a1f]/95 via-[#0d0a1f]/55 to-transparent pointer-events-none" />
            <div className="relative z-10 p-5 flex gap-4">
              <div className="flex-1">
                <h3 className="text-[18px] font-bold tracking-tight">Improve my mood</h3>
                <p className="mt-2.5 text-[13px] leading-[1.55] text-white/60">
                  creates a personalized playlist that starts with 'how you feel' and gently lifts you toward a better mood, using AI it blends emotion and sound to uplift your mood.
                </p>
              </div>
              <div className="flex items-end">
                <button className="h-10 w-10 rounded-full bg-white/[0.06] border border-white/15 backdrop-blur flex items-center justify-center shrink-0">
                  <ArrowUpRight className="h-4 w-4" strokeWidth={2} />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Two small cards */}
        <div className="mt-4 grid grid-cols-2 gap-4">
          <div className="rounded-[24px] p-[1px] bg-gradient-to-b from-white/12 to-white/[0.03]">
            <div className="rounded-[23px] bg-[#0e0b22]/80 backdrop-blur-xl p-4">
              <div className="h-12 w-12 rounded-2xl border border-white/15 flex items-center justify-center mb-3">
                <MusicDnaIcon />
              </div>
              <h4 className="text-[16px] font-bold">Music DNA</h4>
              <div className="mt-3 flex items-end justify-between gap-2">
                <p className="text-[12.5px] leading-[1.4] text-white/85 font-semibold">
                  Personal preference analytics with AI companion.
                </p>
                <button className="h-9 w-9 rounded-full bg-white/[0.06] border border-white/15 flex items-center justify-center shrink-0">
                  <ArrowUpRight className="h-3.5 w-3.5" strokeWidth={2} />
                </button>
              </div>
            </div>
          </div>

          <div className="rounded-[24px] p-[1px] bg-gradient-to-b from-white/12 to-white/[0.03]">
            <div className="rounded-[23px] bg-[#0e0b22]/80 backdrop-blur-xl p-4">
              <div className="h-12 w-12 rounded-2xl border border-white/15 flex items-center justify-center mb-3">
                <SemanticSearchIcon />
              </div>
              <h4 className="text-[16px] font-bold">Semantic search</h4>
              <div className="mt-2 flex items-end justify-between gap-2">
                <p className="text-[12px] leading-[1.45] text-white/60">
                  search music by meaning, not just keywords. Describe your feelings mood or situation.
                </p>
                <button className="h-9 w-9 rounded-full bg-white/[0.06] border border-white/15 flex items-center justify-center shrink-0">
                  <ArrowUpRight className="h-3.5 w-3.5" strokeWidth={2} />
                </button>
              </div>
            </div>
          </div>
        </div>


        {/* Chat input */}
        <div className="mt-6 glass-card rounded-3xl p-4">
          <div className="text-[15px] text-white/55 px-1 pt-1">Message Chatbot Ai....</div>
          <div className="mt-6 flex items-center gap-2.5">
            <button className="h-11 w-11 rounded-full glass-pill flex items-center justify-center shrink-0">
              <Plus className="h-5 w-5" />
            </button>
            <div className="flex-1 h-11 rounded-full glass-pill flex items-center gap-2 px-4">
              <div className="relative">
                <Globe className="h-4 w-4 text-white/70" />
                <Search className="h-2.5 w-2.5 absolute -bottom-0.5 -right-0.5 text-white/70" />
              </div>
              <input
                placeholder="Type your question"
                className="flex-1 bg-transparent outline-none text-[13px] placeholder:text-white/50"
              />
            </div>
            <button className="h-11 w-11 rounded-full glass-pill flex items-center justify-center shrink-0">
              <Mic className="h-5 w-5" />
            </button>
            <button className="h-11 w-11 rounded-full bg-blue-600 flex items-center justify-center shrink-0 shadow-lg shadow-blue-600/40">
              <AudioLines className="h-5 w-5" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function MusicDnaIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-6 w-6" fill="white" aria-hidden>
      <circle cx="9" cy="7" r="3.2" />
      <path d="M3.5 19.5c0-3.2 2.6-5.8 5.5-5.8s5.5 2.6 5.5 5.8H3.5z" />
      <path d="M13.5 19.5l4.3-6.2 4.7 6.2h-9z" />
    </svg>
  );
}

function SemanticSearchIcon() {
  return (
    <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="white" strokeWidth={1.8} strokeLinecap="round" strokeLinejoin="round" aria-hidden>
      <rect x="3" y="4" width="14" height="14" rx="1.5" fill="white" stroke="white" />
      <path d="M3 8h14M7 4v4M11 4v4M15 4v4" stroke="#0e0b22" strokeWidth={1.4} />
      <path d="M14 20l6-6 2 2-6 6h-2v-2z" fill="white" stroke="white" />
      <path d="M18 16l2 2" stroke="#0e0b22" strokeWidth={1.2} />
    </svg>
  );
}

