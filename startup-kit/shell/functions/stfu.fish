function stfu --description "Stop the music"
    killall afplay 2>/dev/null
    echo "🔇 Fine. Back to silence."
end
