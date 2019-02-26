pro _cache_ci_wcs

  COMMON _CI_WCS, astrom

  if n_elements(astrom) EQ 0 then begin
      fname = '../etc/viewer_astrom_index-as_designed.bigtan.fits'
      astrom = mrdfits(fname, 1)
  endif

end

pro _cachec_unwise_wcs

  COMMON _UNWISE_WCS, astrom_unwise
  if n_elements(astrom_unwise) EQ 0 then begin
      fname = '~/unwise/pro/astrom-atlas.fits'
      astrom_unwise = mrdfits(fname, 1)
  endif

end

pro _cache_desi_tiles

  COMMON _DESI_TILES, tiles
  if n_elements(tiles) EQ 0 then begin
      fname = '../etc/desi-tiles.fits'
      tiles = mrdfits(fname, 1)
  endif

end

pro _check_valid_extname, extname

  if n_elements(extname) NE 1 then stop

  valid_extnames = ['CIE', 'CIN', 'CIC', 'CIS', 'CIW']

  if total(extname EQ valid_extnames) EQ 0 then stop

end

function corner_pixel_coords

  x = [-0.5d,   -0.5d, 3071.5d, 3071.5d]
  y = [-0.5d, 2047.5d, 2047.5d,   -0.5d]

  outstr = replicate({x: 0.0d, y: 0.0d}, 4)

  outstr.x = x
  outstr.y = y

  return, outstr
end

function get_radec_coords, telra, teldec, ci_extname, $
                           corner_coords=corner_coords

  if n_elements(telra) NE 1 then stop
  if n_elements(teldec) NE 1 then stop

  if size(telra, /type) NE 5 then stop
  if size(teldec, /type) NE 5 then stop

  if (telra LT 0) OR (telra GE 360) then stop
  if (teldec LT -90) or (teldec GT 90) then stop

; don't use literally every single pixel, but sample only at the rate 
; that's necessary !!

; want images that 768 x 512 pixels, to match dustin

  xbox = lindgen(768, 512) MOD 768
  ybox = lindgen(768, 512) / 768

  xbox = xbox*4 + 2
  ybox = ybox*4 + 2

  _cache_ci_wcs
  COMMON _CI_WCS, astrom

  astr = astrom[where(astrom.extname EQ ci_extname)]

  astr.crval = [telra, teldec]

  xy2ad, xbox, ybox, astr, abox, dbox

  outstr = {ra: abox, dec: dbox}  

  corners = corner_pixel_coords()
  xy2ad, corners.x, corners.y, astr, ra_corners, dec_corners
  
  corner_coords = {ra: ra_corners, dec: dec_corners}

  return, outstr
end

function gather_unwise_pixels, telra, teldec, ci_extname, band

  if n_elements(band) NE 1 then stop
  if (band NE 1) AND (band NE 2) then stop

  coords = get_radec_coords(telra, teldec, ci_extname, $
                            corner_coords=corners)

  coadd_ids = strarr(4)
  for i=0L,n_elements(corners.ra)-1 do begin
      coadd_id = get_best_tile(corners.ra[i], corners.dec[i])
      coadd_ids[i] = coadd_id
  endfor

  coadd_id_u = unique(coadd_ids)

  _cachec_unwise_wcs

  COMMON _UNWISE_WCS, astrom_unwise

  composite = fltarr(768, 512)
  wt = fltarr(768, 512)

  print, n_elements(unique(coadd_id_u)), ' @@@@@@@@@@@@@@@@@@'

  for i=0L, n_elements(coadd_id_u)-1 do begin
      coadd_id = coadd_id_u[i]

      fname_unwise = '/global/projecta/projectdirs/cosmo/work/wise/outputs/merge/neo4/fulldepth/' + strmid(coadd_id, 0, 3) + '/' + coadd_id + '/unwise-' + $
      coadd_id + '-w' + string(band, format='(I1)') + '-img-u.fits'

      if ~file_test(fname_unwise) then stop

      print, 'READING: ', fname_unwise
      im_unwise = readfits(fname_unwise)
      astr = astrom_unwise[where(astrom_unwise.coadd_id EQ coadd_id)]

      ad2xy, coords.ra, coords.dec, astr, xx, yy
      interp = interpolate(im_unwise, xx, yy)
      in_image = (xx GT -0.5) AND (xx LT 2047.5) AND $
                 (yy GT -0.5) AND (yy LT 2047.5)
      composite += interp*in_image
      wt += in_image
  endfor

  if total(wt EQ 0) NE 0 then stop

  result = composite/wt

  return, result
end

pro predicted_wise_images, outdir=outdir

  if ~keyword_set(outdir) then $
      outdir = '/project/projectdirs/desi/users/ameisner/CI/software_review/vis/aaron_unwise_pred'

  if ~file_test(outdir) then stop

  _cache_desi_tiles
  COMMON _DESI_TILES, tiles

  ; need to generalize this...
  tile_ids = [575, 2738]

  valid_extnames = ['CIE', 'CIN', 'CIC', 'CIS', 'CIW']

  for i=0L, n_elements(tile_ids)-1 do begin
      w = where(tiles.tileid EQ tile_ids[i], nw)
      if nw NE 1 then stop
      ra = tiles[w[0]].ra
      dec = tiles[w[0]].dec
      outname = 'ci_viewer_' + string(tile_ids[i], format='(I05)') + $
          '-aaron.fits'
      if file_test(outname) then stop
      outname = concat_dir(outdir, outname)
      print, 'Planning to write: ' + outname
      for j=0, 4 do begin
          ci_extname = valid_extnames[j]
          for band=1, 2 do begin
              im = gather_unwise_pixels(ra, dec, ci_extname, band)
              ; decision not to put astrometry into headers
              mkhdr, header, im, /IMAGE, extend=(~file_test(outname))
              ; put a useful extname like CIEW1
              sxaddpar, header, 'EXTNAME', ci_extname + 'W' + $
                  string(band, format='(I1)')
              writefits, outname, im, header, append=file_test(outname)
          endfor
      endfor
  endfor

end
