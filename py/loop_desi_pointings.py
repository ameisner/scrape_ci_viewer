import astropy.io.fits as fits
import numpy as np
from time import sleep
from drive_ci_viewer import get_ci_image_urls
import pickle

def random_pointings_subset(n=100, seed=99, desi_pass=0):
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

def loop_desi_pointings(n=100, seed=99, desi_pass=0, delay_seconds=10.0):

    tiles = random_pointings_subset(n=n, seed=seed, desi_pass=desi_pass)

    result = dict(zip(tiles['TILEID'], [None]*n))

    for i, tile in enumerate(tiles):
        print('Working on tile ' + str(i+1) + ' of ' + str(n))
        result[tile['TILEID']] = get_ci_image_urls(tile['RA'], tile['DEC'])
        if i != (n-1):
            sleep(delay_seconds)
    return result
