function gv --description 'golden-voice: gv <name> | gv say "text" | gv save <name> "text" | gv (list)'
    set -l base ~/.claude/local-tts
    set -l clips $base/clips

    if test (count $argv) -eq 0
        echo "🎙️  named clips:"
        for d in $base $clips
            test -d $d; or continue
            for f in $d/*.wav
                test -f $f; or continue
                set -l n (basename $f .wav)
                test "$n" = my-voice; and continue
                set -l dur (ffprobe -v error -show_entries format=duration -of csv=p=0 $f 2>/dev/null)
                printf "   gv %-32s (%ss)\n" $n (string sub -l 4 -- $dur)
            end
        end
        set -l cn (count $base/cache/*.wav 2>/dev/null)
        echo ""
        echo "   gv say \"text\"           → speak live in your voice (cached: $cn phrases, repeats instant)"
        echo "   gv save <name> \"text\"   → mint a reusable named clip (for hooks etc.)"
        return 0
    end

    switch $argv[1]
        case say
            $base/local-tts.sh $argv[2..-1]
        case save
            set -l name $argv[2]
            set -l text (string join ' ' $argv[3..-1])
            if test -z "$name"; or test -z "$text"
                echo "usage: gv save <name> \"text to speak\""; return 1
            end
            echo "minting '$name' (first time ~25s, then cached)…"
            env LOCAL_TTS_SAVE_AS=$name LOCAL_TTS_NOPLAY=1 $base/local-tts.sh $text
            and echo "✅ saved → $clips/$name.wav   ·   play: gv $name"
        case '*'
            for f in $clips/$argv[1].wav $base/$argv[1].wav
                if test -f $f
                    afplay $f
                    return 0
                end
            end
            echo "no clip '$argv[1]'. run 'gv' to list."
            return 1
    end
end
