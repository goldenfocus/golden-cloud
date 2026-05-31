function gv --description 'golden-voice: say/record/play/export + live controls'
    set -l base ~/.claude/local-tts
    set -l sdir $base/voices/me/samples

    if test (count $argv) -eq 0
        echo "🎙️  golden-voice"
        echo "   gv say \"text\"        speak text now (cached, repeats instant)"
        echo "   gv play [clip|last] [full|medium|recap]   read clipboard / last answer"
        echo "   gv record [label]    add a voice sample (more = better clone)"
        echo "   gv samples           list your voice samples"
        echo "   gv export <name> ..  mint a library clip (wav+opus+mp3)"
        echo "   gv auto on|off       toggle auto-narration"
        echo "   gv pause | ff | x2 | stop   live playback controls"
        echo "   gv set <key> <val>   edit a setting"
        return 0
    end

    switch $argv[1]
        case say
            # synth (no play), then play through the IPC player so gv pause/ff/x2/stop work
            set -l wav (env LOCAL_TTS_BACKEND=xtts LOCAL_TTS_NOPLAY=1 $base/local-tts.sh $argv[2..-1])
            test -s "$wav"; and $base/bin/gv-play.sh $wav
        case play
            $base/bin/gv-pipe.sh $argv[2] $argv[3] $argv[4]
        case record
            mkdir -p $sdir
            set -l existing (ls $sdir/*.wav 2>/dev/null)
            if test -z "$existing"; and test -f $base/my-voice.wav
                cp $base/my-voice.wav $sdir/original.wav
            end
            set -l label (string join '-' $argv[2..-1] | string replace -ra '[^A-Za-z0-9]+' '-')
            set -l name (date +%Y-%m-%d_%H%M%S)
            test -n "$label"; and set name "$name-$label"
            SECS=30 OUT=$sdir/$name.wav $base/record-voice.sh
            test -s $sdir/$name.wav; or begin; echo "recording failed"; return 1; end
            echo "▶ playing back…"; afplay $sdir/$name.wav
            echo "✅ saved · clone now averages "(count (ls $sdir/*.wav))" sample(s)"
        case samples
            set -l files (ls $sdir/*.wav 2>/dev/null)
            test -z "$files"; and begin; echo "no samples — gv record"; return 0; end
            for f in $files
                set -l dur (ffprobe -v error -show_entries format=duration -of csv=p=0 $f 2>/dev/null)
                printf "   %-30s (%ss)\n" (basename $f .wav) (string sub -l 4 -- $dur)
            end
        case export
            $base/bin/gv-export.sh $argv[2] (string join ' ' $argv[3..-1])
        case auto
            $base/xtts-venv/bin/python $base/bin/pa-settings.py set auto $argv[2]
        case set
            $base/xtts-venv/bin/python $base/bin/pa-settings.py set $argv[2] $argv[3]
        case pause ff x2 stop
            $base/bin/gv-ctl.sh $argv[1]
        case '*'
            echo "unknown: $argv[1] — run 'gv' for help"; return 1
    end
end
