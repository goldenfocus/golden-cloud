function push --description "Ah, push it — push it real good"
    if test (count $argv) -eq 1; and test (string lower -- $argv[1]) = "it"
        # Kill any previous push-it playback
        killall afplay 2>/dev/null

        # 100 high-creator-vibe quotes
        set -l quotes \
            "Ship it before it's perfect. Perfect never ships." \
            "The best architects build bridges while others debate blueprints." \
            "Push code, not deadlines." \
            "Every git push is a tiny act of courage." \
            "You're not debugging — you're discovering." \
            "The universe rewards builders, not planners." \
            "Ctrl+S won't save you. Ctrl+P(ush) will." \
            "Real artists ship. — Steve Jobs" \
            "Move fast and fix things." \
            "The code you ship today is worth more than the code you plan tomorrow." \
            "Build the plane while flying it. That's the only way." \
            "Shipping is a muscle. Train it." \
            "Your commit history is your autobiography." \
            "The deploy button is just a confidence button." \
            "Done is better than perfect. Pushed is better than done." \
            "You don't find product-market fit. You push your way to it." \
            "Momentum > motivation. Push." \
            "Every master was once a disaster who kept pushing." \
            "The only bad deploy is the one you never made." \
            "Think less. Build more. Ship faster." \
            "Architects don't wait for permits in their dreams." \
            "The gap between you and your vision? One push." \
            "Fortune favors the shipped." \
            "What you push today compounds tomorrow." \
            "Stop polishing. Start pushing." \
            "Push through the resistance. The other side is flow." \
            "Code is poetry. Deploying is publishing." \
            "The best time to push was yesterday. The second best time is now." \
            "Your users don't care about your git log. They care about your git push." \
            "Creators create. Shippers ship. Be both." \
            "One push closer to the thing you're meant to build." \
            "Fear is the mind-killer. Push is the fear-killer." \
            "The architect who builds beats the critic who talks." \
            "Build like nobody's watching. Push like everybody is." \
            "Every push is a vote for the developer you want to become." \
            "You are one push away from a completely different life." \
            "Ideas are cheap. Execution is expensive. Shipping is priceless." \
            "The warehouse of abandoned side projects has no deploy logs." \
            "Push early, push often, push with conviction." \
            "Your future self will thank you for this push." \
            "Clarity comes from action, not thought." \
            "The world is run by people who push to main." \
            "Not all heroes wear capes. Some just push to prod on Friday." \
            "Build in public. Push in production. Learn in real-time." \
            "Doubt kills more dreams than bugs ever will." \
            "Great things are built by people who push when it's uncomfortable." \
            "You can't steer a parked car. Push." \
            "The magic you're looking for is in the work you're avoiding." \
            "Make it work. Make it right. Make it live." \
            "Dreams don't work unless you deploy them." \
            "Less meetings, more pushing." \
            "The road to production is paved with good commits." \
            "Push first. Apologize never. Fix forward." \
            "Be the chaos monkey you wish to see in the world." \
            "You miss 100% of the deploys you don't make." \
            "The best code is the code that's running." \
            "Deploy your way to clarity." \
            "What's the worst that could happen? A rollback? Push." \
            "Behind every successful product is 10,000 pushes." \
            "Your staging environment is lying to you. Push to prod." \
            "Legends don't sit in draft mode." \
            "Creation is the ultimate flex." \
            "Push like your rent depends on it. Because it does." \
            "The architect's secret: build first, name it later." \
            "Every line of code deployed is a line of doubt destroyed." \
            "Trust the process. Push the code." \
            "Shipping is healing." \
            "Today's push is tomorrow's foundation." \
            "You are the CI/CD pipeline of your own destiny." \
            "Building something from nothing is the closest thing to magic." \
            "The commit message is your battle cry." \
            "Perfection is the enemy of production." \
            "Push through imposter syndrome. Your code compiles. You belong." \
            "Architects don't just draw — they deploy." \
            "The world doesn't need another TODO. It needs a push." \
            "Ship or it didn't happen." \
            "Every great company started with one reckless push to main." \
            "Be ungovernable. Push to prod." \
            "Your keyboard is a weapon. Your terminal is a launchpad." \
            "Build. Break. Fix. Push. Repeat." \
            "The only merge conflict that matters is between you and inaction." \
            "Stop iterating in your head. Start iterating in production." \
            "Comfort zones don't have deploy buttons." \
            "The diff between who you are and who you want to be is one push." \
            "Manifest in main, not in drafts." \
            "You don't need permission to push greatness." \
            "Ships are safe in harbor, but code is safe nowhere until deployed." \
            "Make the push. Take the leap. Trust the tests." \
            "If it scares you, it's probably worth deploying." \
            "Your next push could change everything." \
            "Push with purpose. Deploy with love." \
            "The terminal is your temple. Push is your prayer." \
            "No one ever looked back and wished they'd pushed less." \
            "Build what excites you. Push what terrifies you." \
            "The universe conspires in favor of those who push." \
            "Every push is a love letter to your future users." \
            "Pushing is just believing with extra steps." \
            "Not today, merge conflicts. Not today." \
            "Inhale confidence. Exhale code. Push." \
            "They said it couldn't be done. Then someone pushed to main." \
            "You're not just pushing code. You're pushing culture." \
            "Salt-N-Pepa said it best. Push it real good."

        # Pick a random quote
        set -l idx (random 1 (count $quotes))
        set -l quote $quotes[$idx]

        # Random ASCII art (8 variations)
        set -l art_pick (random 1 8)

        # Colors
        set -l pink (set_color ff69b4)
        set -l cyan (set_color 00ffff)
        set -l yellow (set_color ffff00)
        set -l green (set_color 00ff88)
        set -l magenta (set_color ff00ff)
        set -l white (set_color white)
        set -l dim (set_color 888888)
        set -l reset (set_color normal)

        echo ""

        switch $art_pick
            case 1
                echo $pink"    ╔═══════════════════════════╗"$reset
                echo $pink"    ║"$cyan"  ⚡ P U S H  I T ⚡  "$pink"║"$reset
                echo $pink"    ╚═══════════════════════════╝"$reset
                echo $yellow"         \\   ^__^"$reset
                echo $yellow"          \\  (@@)\\_______"$reset
                echo $yellow"             (__)\\       )\\/\\"$reset
                echo $yellow"                 ||----w |"$reset
                echo $yellow"                 ||     ||"$reset
            case 2
                echo $magenta"       ┌─────────────────────┐"$reset
                echo $magenta"       │"$green"  🚀 PUSH IT REAL GOOD "$magenta"│"$reset
                echo $magenta"       └──────────┬──────────┘"$reset
                echo $cyan"              ┌───┴───┐"$reset
                echo $cyan"              │ ◉   ◉ │"$reset
                echo $cyan"              │   ▽   │"$reset
                echo $cyan"              │  ───  │"$reset
                echo $cyan"              └───────┘"$reset
                echo $yellow"             /|\\     /|\\"$reset
                echo $yellow"            / | \\   / | \\"$reset
            case 3
                echo $green"    ██████╗ ██╗   ██╗███████╗██╗  ██╗"$reset
                echo $green"    ██╔══██╗██║   ██║██╔════╝██║  ██║"$reset
                echo $cyan"    ██████╔╝██║   ██║███████╗███████║"$reset
                echo $cyan"    ██╔═══╝ ██║   ██║╚════██║██╔══██║"$reset
                echo $magenta"    ██║     ╚██████╔╝███████║██║  ██║"$reset
                echo $magenta"    ╚═╝      ╚═════╝ ╚══════╝╚═╝  ╚═╝"$reset
                echo $yellow"              ⚡ I T ⚡"$reset
            case 4
                echo $cyan"         *    .  *       .        *"$reset
                echo $yellow"    .  *    🚀      *    .    ."$reset
                echo $yellow"        .       *         *"$reset
                echo $pink"     *     PUSH IT     .      *"$reset
                echo $pink"    .    TO THE MOON    *"$reset
                echo $cyan"       *    .    *    .       *"$reset
                echo $green"    .      *        .    *     ."$reset
            case 5
                echo $magenta"    ┏━━━━━━━━━━━━━━━━━━━━━━━━━┓"$reset
                echo $magenta"    ┃"$reset$yellow"  ░█▀█░█░█░█▀▀░█░█░░░░░  "$magenta"┃"$reset
                echo $magenta"    ┃"$reset$yellow"  ░█▀▀░█░█░▀▀█░█▀█░░░░░  "$magenta"┃"$reset
                echo $magenta"    ┃"$reset$yellow"  ░▀░░░▀▀▀░▀▀▀░▀░▀░▀░▀░  "$magenta"┃"$reset
                echo $magenta"    ┗━━━━━━━━━━━━━━━━━━━━━━━━━┛"$reset
                echo $cyan"            (╯°□°)╯︵ 🚀"$reset
            case 6
                echo $green"          .  *  .    *    .  *"$reset
                echo $yellow"    *  .    ___________    .  *"$reset
                echo $yellow"       .  /           \\  ."$reset
                echo $pink"     *   |  PUSH  IT  |   *"$reset
                echo $pink"    .    |  REAL GOOD |    ."$reset
                echo $yellow"       .  \\_________/  .   *"$reset
                echo $cyan"     *    |    |||    |    ."$reset
                echo $cyan"    .     |    |||    |  *"$reset
                echo $green"       🔥🔥🔥🔥🔥🔥🔥"$reset
            case 7
                echo $pink"    ╭──────────────────────────╮"$reset
                echo $pink"    │"$reset"  "$cyan"♪ ♫"$yellow" Push it real good "$cyan"♫ ♪"$reset"  "$pink"│"$reset
                echo $pink"    ╰──────────────────────────╯"$reset
                echo $magenta"         ♪  \\(^o^)/  ♫"$reset
                echo $yellow"            /    \\"$reset
                echo $yellow"           /|    |\\"$reset
                echo $green"          ♫  ♪  ♫  ♪"$reset
            case 8
                echo $cyan"    ░░░░░░░░░░░░░░░░░░░░░░░░░░░"$reset
                echo $cyan"    ░"$pink"  ███ █ █ ███ █ █         "$cyan"░"$reset
                echo $cyan"    ░"$pink"  █ █ █ █ ██  ███  █ ███  "$cyan"░"$reset
                echo $cyan"    ░"$pink"  ███ ███ ███ █ █  █  █   "$cyan"░"$reset
                echo $cyan"    ░░░░░░░░░░░░░░░░░░░░░░░░░░░"$reset
                echo $yellow"           ᕦ(ò_óˇ)ᕤ"$reset
        end

        echo ""
        echo $dim"    ✦ "$white$quote$reset
        echo ""

        # Play the full song in background
        afplay ~/.config/fish/sounds/push-it-full.mp3 &
        disown
    else
        command push $argv
    end
end
