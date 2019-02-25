import astropy.io.fits as fits
import numpy as np
from time import sleep

def loop_desi_pointings(n=100, seed=99, desi_pass=0, delay_seconds=10.0):
    desi_tiles = fits.getdata('../etc/desi-tiles.fits')

    desi_tiles = desi_tiles[(desi_tiles['IN_DESI'] == True) & 
                            (desi_tiles['PASS'] == desi_pass)]

    assert(n <= len(desi_tiles))

    np.random.seed(seed=seed)
    # random sample of size n (no duplicates)
    desi_tiles = desi_tiles[np.random.choice(np.arange(len(desi_tiles)), size=n, replace=False)]

    assert(len(desi_tiles) == n)
    assert(len(np.unique(desi_tiles['TILEID'])) == n)

    return desi_tiles
