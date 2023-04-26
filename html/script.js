let difficulty = 0

let difficulties = [
    [9, 166.66666666666666666666666, 5],
    [25, 100, 10],
    [49, 71.428571, 20]
]

window.addEventListener('message', (event) => {
    if (event.data.type == 'StartGame') {
        StartGame(event.data.groupID)
    }
});

function StartGame(groupID) {
    $('body').css('opacity', '1.0')
    let health = 100;
    let num = difficulties[difficulty][0]
    let isGood = []


    let list = []
    for (let index = 0; index < num; index++) {
        list.push(index)
    }

    for (let index = 0; index < difficulties[difficulty][2]; index++) {
        shuffle(list)
        isGood.push(list[0])
        list.shift()

    }

    for (let index = 0; index < num; index++) {
        let isGoodTile = isGood.includes(index)
        $('.container').append(`
            <div class="module" style = "width:${difficulties[difficulty][1]}px;height:${difficulties[difficulty][1]}px;" ${isGoodTile == true ? "good=1":""}>
                <img src="check.png" class = "check">
                <img src="x.png" class = "x">
                <img src="water.png">
            </div>
        `)
    }

    let unfoundTiles = difficulties[difficulty][2];
    $('.module').click(function() {
        if ($(this).attr('clicked') == 1) return;

        $(this).attr('clicked', 1)
        if ($(this).attr('good') == 1) {
            $(this).find('.check').css('display', 'inline')
            unfoundTiles--
            if (unfoundTiles == 0) {
                $.post(`https://${GetParentResourceName()}/GameFinish`, JSON.stringify({ win: true, group: groupID }));
                EndGame()
            }
        } else {
            $(this).find('.x').css('display', 'inline')
            health -= 10;
            $('#healthbar').css('width', `${health}%`)
            if (health <= 0) {
                $.post(`https://${GetParentResourceName()}/GameFinish`, JSON.stringify({ win: false, group: groupID }));
                EndGame();
            }
        }
    })

    let gameTick = setInterval(() => {
        health -= 1
        $('#healthbar').css('width', `${health}%`)
        if (health <= 0) {
            $.post(`https://${GetParentResourceName()}/GameFinish`, JSON.stringify({ win: false, group: groupID }));
            EndGame();
            clearInterval(gameTick)
        }
    }, 500);
}

function shuffle(array) {
    array.sort(() => Math.random() - 0.5);
}

function EndGame() {
    $('body').css('opacity', '0.0')
    setTimeout(() => {
        $('.module').each(function() {
            $(this).remove();
        })
        $('#healthbar').css('width', `100%`)
    }, 500);
}