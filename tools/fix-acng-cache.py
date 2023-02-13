#!/usr/bin/python3

# This tool fixes a broken apt-cacher-ng cache.
#
# Just run it like: `python3 fix-acng-cache.py` in the /var/cache/apt-cacher-ng
# directory.
#
# apt-cacher-ng sometimes leaves incomplete files in its cache, which
# will cause 503 errors, when the cache data is then used in offline
# mode. This script fixes those files by re-downloading them, the
# required information for this is in the accompanying .head file.
#
# apt-cacher-ng should be stopped while fixing the cache and should
# not be started without being in offline mode afterwards (as this may
# break the cache again).
#
# Of course there's a risk for race conditions (if a package list
# changed, and now references a version of a package that's not yet in
# the cache), the script emits a warning if the file length changed
# to detect most of these cases.

import argparse
import os
import http.client
import urllib.request
import shutil

ap = argparse.ArgumentParser()
ap.add_argument('dir', nargs='?', default='.')
args = ap.parse_args()


def read_head_file(fname):
    with open(fname, "rb") as f:
        f.readline()  # chop off the status line
        return http.client.parse_headers(f)


for path, dirs, files in os.walk(args.dir):
    for file_ in files:
        if file_.endswith('.head'):
            headfile = os.path.join(path, file_)
            realfile = os.path.join(path, file_[:-len('.head')])
            headers = read_head_file(headfile)

            headersize = int(headers['Content-Length'])
            try:
                realsize = os.stat(realfile).st_size
            except FileNotFoundError:
                realsize = 0

            if realsize != headersize:
                print("Repairing file {}".format(realfile))

                with urllib.request.urlopen(headers['X-Original-Source']) as conn:
                    if conn.status != 200:
                        print("Error retrieving the file from the original source.")
                    with open(realfile, "wb") as f:
                        shutil.copyfileobj(conn, f)
                    realsize = os.stat(realfile).st_size
                    if realsize != headersize:
                        print("Warning: Either the file changed "
                              "in the mean-time or the download is broken.")
