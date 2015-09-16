# hubfavor

> Determine who in a given GitHub Organization is most likely to do you a favor

This was a super quick hack when I needed a favor from a large-ish software
company but didn't know anyone who worked there.  I figured someone who followed
me on GitHub and had starred my projects was most likely to recognize my
username and respond favorably.

Yes, I realize this should probably be considered borderline sociopathic.

Throwing this on GitHub anyhow so others can (ab)use it.


### Usage
Obtain a [GitHub Access Token] and set it as an environment variable
`GITHUB_ACCESS_TOKEN` (The standard convention of storing that in a [`.env`]
file will also be respected).

    $ hubfavor --help
    Usage: hubfavor [options] <organization>
        -u, --user=mroth                 GitHub username of yourself
        -c, --threads=20                 Number of simultaneous queries
        -v, --verbose                    Output scanned users regardless of match
        -h, --help                       Display this help screen

    $ hubfavor flickr
    Need a favor from someone at flickr, huh?
    Retrieving followers for mroth... found 343.
    Retrieving organization members of flickr... found 16.
    Stargazing... (20 simultaneous queries)
    -> hartsell            [🌟 bogan-martin-award]
    -> scottschiller       [👀 follower]
    -> rharmes             [👀 follower][🌟 scmpuff]
    -> bertrandom          [👀 follower]

    Found 4 candidates in 2.36 seconds.
    Most likely candidate: rharmes

Sample queries do not reflect the actual organization that was the impetus for
this script. :smile:

[GitHub Access Token]: https://help.github.com/articles/creating-an-access-token-for-command-line-use/
[`.env`]: https://github.com/bkeepers/dotenv

### Caveats

1. I realized after the fact that this probably won't work well at all unless
you have a fairly decent amount of popular GitHub projects and followers. That's
okay, the best solution if you don't is to write more open source software.

2. Running at the default concurrency (20) on a large organization will trigger
GitHub's abuse-detection rate limiting pretty quickly.  If you aren't in a rush,
use `-c5` or something to reduce the simultaneous queries.
