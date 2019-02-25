import requests
import pickle
import os
from time import sleep

def load_scraping_results(fname):
    assert(os.path.exists(fname))

    data = pickle.load(open(fname, "rb"))

    return data

def retrieve_one_png(url, wise=False):
    # if wise kw arg set to true then 
    # get the wise image instead of the 
    # legacysurvey image

    if wise:
        url = url.replace('ls-dr67', 'unwise-neo4')

    r = requests.get(url)

    return r

def write_one_jpg(r, outdir, tileid, ci_name, wise=False):

    # r is requests object

    # construct the output name
    survey_name = ('ls' if not wise else 'wise')
    outname = 'ci_viewer_'  + str(tileid).zfill(5)  + '_' + ci_name + '-' + survey_name + '.jpg'
    outname = os.path.join(outdir, outname)

    print(outname)

    open(outname,"wb").write(r.content)

def retrieve_all_pngs(fname_scrape, outdir, delay_seconds=2.0):
    data = load_scraping_results(fname_scrape)

    for tileid, url_dict in data.items():
        for ci_name, url in url_dict.items():
            for wise in [False, True]:
                r = retrieve_one_png(url, wise=wise)
                write_one_jpg(r, outdir, tileid, ci_name, wise=wise)
                sleep(delay_seconds)
