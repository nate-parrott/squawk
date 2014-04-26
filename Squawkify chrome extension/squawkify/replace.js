// stolen from https://chrome.google.com/webstore/detail/skeyboardleopard/oheflacdocadefgdpiimpapbkomhgbbe
// obtained from http://stackoverflow.com/questions/6012163/whats-a-good-alternative-to-html-rewriting/6012345#6012345
jQuery.fn.textWalk = function( fn ) {
    this.contents().each( jwalk );

    function jwalk() {
        var nn = this.nodeName.toLowerCase();
        if( nn === '#text' ) {
            fn.call( this );
        } else if( this.nodeType === 1 && this.childNodes && this.childNodes[0] && nn !== 'script' && nn !== 'textarea' ) {
            $(this).contents().each( jwalk );
        }
    }
    return this;
};

(function() {
    var regex = new RegExp("\\b(bach|walk|talk|mock|hawk|balk|stalk|mohawk|rock|lock|loc|loch|block|clock|shock|flock|hoc|knock|bloc|chalk|cock|dock|mock|frock|doc|doch|proc|sock|chock|crock|hock|pock|bock|jock|mach|wok|caulk|choc|schlock|stock|unlock|smock|macaque|restock|ballcock|manioc|interlock|hollyhock|hammerlock|windsock|aftershock|antiknock|overstock|laughingstock|electroshock|walks|talks|mocks|hawks|balks|stalks|mohawks|rocks|locks|locs|lochs|blocks|clocks|shocks|flocks|hocs|knocks|blocs|chalks|cocks|docks|mocks|frocks|docs|dochs|procs|socks|chocks|crocks|hocks|pocks|bocks|jocks|machs|woks|caulks|chocs|schlocks|stocks|unlocks|smocks|macaques|restocks|ballcocks|maniocs|interlocks|hollyhocks|hammerlocks|windsocks|aftershocks|antiknocks|overstocks|laughingstocks|electroshocks)\\b", "ig");

    var titleCase = function(word) {
        return word.substring(0,1).toUpperCase() + word.substring(1).toLowerCase();
    }

    var matchCase = function(original, replacement) {
        if (original.substring(original.length-1).toLowerCase()=='s') replacement += "s";
        if (original == original.toUpperCase()) {
            return replacement.toLowerCase();
        }
        if (original == titleCase(original)) {
            return titleCase(replacement);
        }
        if (original == original.toLowerCase()) {
            return replacement.toLowerCase();
        }
        return replacement;
    }

    var replace = function(x) {
        return x.replace(regex, function(x) {return matchCase(x, "squawk")})
    }
    $('body').textWalk(function() {
        this.data = replace(this.data);
    });
})();

