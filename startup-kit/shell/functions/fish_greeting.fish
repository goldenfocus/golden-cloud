function fish_greeting
    set -l quotes \
        "Ship it. Learn. Iterate." \
        "Focus is saying no to good ideas." \
        "Done is better than perfect." \
        "Build momentum, not plans." \
        "Deep work compounds." \
        "Small commits, big results." \
        "Execution eats strategy for breakfast." \
        "The best code ships today." \
        "Reduce scope, not quality." \
        "Clarity comes from action, not thought." \
        "One thing at a time. Finish it." \
        "Stop planning. Start building." \
        "Momentum is a habit." \
        "The fastest way to learn is to ship." \
        "Protect your focus like it pays you." \
        "Less meetings. More making." \
        "Craft compounds over time." \
        "Every keystroke should earn its place." \
        "Your future self will thank your focus." \
        "Shipping is a muscle. Train it." \
        "Good enough now beats perfect never." \
        "Cut the noise. Do the work." \
        "Make it work. Make it right. Ship it." \
        "Distraction is the enemy of depth." \
        "Simplify, then execute." \
        "First, solve the problem. Then, code." \
        "Progress over perfection." \
        "You don't rise to your goals. You fall to your systems." \
        "Do fewer things, better." \
        "What you ship defines you." \
        "The obstacle is the way." \
        "Architect first. Code second." \
        "Complexity is debt. Simplicity is wealth." \
        "Your systems define your ceiling." \
        "Less but better." \
        "Constraints breed creativity." \
        "Every decision is a trade-off. Own it." \
        "The fastest code is the code you never write." \
        "Make it obvious. Then make it fast." \
        "Trust the process. Ship the result." \
        "Default to action." \
        "Delete more than you write." \
        "Speed is a feature." \
        "Think in systems. Build in iterations." \
        "The right abstraction is worth a thousand lines." \
        "Boring technology wins." \
        "Automate the repetitive. Create the unique." \
        "Your code is a letter to the next developer." \
        "Optimize for change, not for perfection." \
        "Build the smallest thing that works." \
        "Debugging is twice as hard as writing the code." \
        "Make the invisible visible." \
        "Earn your complexity." \
        "Don't solve problems you don't have." \
        "The best feature is the one you don't build." \
        "Write code for humans, not machines." \
        "Clear is better than clever." \
        "Structure enables freedom." \
        "Iterate faster than you plan." \
        "Be water." \
        "The map is not the territory." \
        "Deploy with confidence, not with hope." \
        "Move fast and fix things." \
        "Your users don't care about your stack." \
        "Simple scales. Complex fails." \
        "What would this look like if it were easy?" \
        "Momentum beats motivation." \
        "Solve for today. Design for tomorrow." \
        "Every bug is a lesson. Every fix is growth." \
        "Start ugly. Ship clean." \
        "The best time to refactor was last sprint. The second best is now." \
        "Code is temporary. Architecture endures." \
        "One commit at a time." \
        "The answer is always in the data." \
        "Build bridges, not walls." \
        "Talk is cheap. Show me the code." \
        "Energy flows where attention goes." \
        "Your future self is watching." \
        "Fail fast. Learn faster." \
        "Zero inbox. Full output." \
        "Ship beats perfect." \
        "Every line of code is a liability." \
        "Measure twice. Deploy once." \
        "Great products are edited, not written." \
        "The system is the solution." \
        "Break it down. Build it up." \
        "Be the change you want to ship." \
        "Your habits are your infrastructure." \
        "Clarity is kindness." \
        "The best debugging tool is a good night's sleep." \
        "Small wins compound." \
        "Stay curious. Stay shipping." \
        "Complexity is the enemy of execution." \
        "What gets measured gets managed." \
        "Don't count the days. Make the days count." \
        "Vision without execution is hallucination." \
        "The only constant is change. Embrace it." \
        "Discipline is choosing what you want most over what you want now."

    # Rainbow ASCII art first
    set -l cowfiles \
        alpaca amy baby_yoda batman bender bender-md blowfish bong bowser bud-frogs bunny \
        buzz-lightyear captain-falcon cat catwoman cheese cower cupcake daemon default \
        dragon dragon-and-cow elephant elephant-in-snake eyes fire flaming-sheep fox \
        fox-winking ghost ghostbusters golden-eagle head-in hellokitty homer king kirby \
        kiss kitty knight knuckles koala kosh lightbulb link llama luigi luke-koala mario \
        master-chief mech-and-cow meow metaknight milk moofasa mooninites moose mutilated \
        owl peach pikachu pikachu2 pikachu3 poison-ivy portal-turrets queen r2d2 ren \
        roadrunner samus seahorse shadow sheep skeleton small solid-snake sonic space-ghost \
        starfox stegosaurus stimpy streex superman-flying supermilker surgery sus tails \
        three-eyes turkey turtle tux udder vader vader-koala wario wizard www yoda yoshi \
        zelda

    set -l pick $cowfiles[(random 1 (count $cowfiles))]
    set -l idx (random 1 (count $quotes))

    # Fortune quote in the cowsay speech bubble (rainbow)
    fortune ~/.fortune/vibes | cowsay -f $pick | lolcat

    # Our ✦ quote right before the prompt
    echo ""
    set_color brblack
    echo "  ✦ "$quotes[$idx]
    set_color normal
end
