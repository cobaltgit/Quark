const libasound = "libasound.so.2"

type
  SndMixerT*        = pointer
  SndMixerElemT*    = pointer
  SndMixerSelemIdT* = pointer

proc snd_mixer_open*(mixer: ptr SndMixerT, mode: cint): cint
  {.importc, dynlib: libasound.}

proc snd_mixer_close*(mixer: SndMixerT): cint
  {.importc, dynlib: libasound.}

proc snd_mixer_attach*(mixer: SndMixerT, name: cstring): cint
  {.importc, dynlib: libasound.}

proc snd_mixer_load*(mixer: SndMixerT): cint
  {.importc, dynlib: libasound.}

proc snd_mixer_selem_register*(mixer: SndMixerT,
                                options: pointer,
                                classp: pointer): cint
  {.importc, dynlib: libasound.}

proc snd_mixer_selem_id_sizeof*(): csize_t
  {.importc, dynlib: libasound.}

proc snd_mixer_selem_id_set_name*(obj: SndMixerSelemIdT, val: cstring)
  {.importc, dynlib: libasound.}

proc snd_mixer_selem_id_set_index*(obj: SndMixerSelemIdT, val: cuint)
  {.importc, dynlib: libasound.}

proc snd_mixer_find_selem*(mixer: SndMixerT,
                            id: SndMixerSelemIdT): SndMixerElemT
  {.importc, dynlib: libasound.}

proc snd_mixer_selem_get_playback_volume_range*(elem: SndMixerElemT,
                                                 minVal: ptr clong,
                                                 maxVal: ptr clong): cint
  {.importc, dynlib: libasound.}

proc snd_mixer_selem_set_playback_volume_all*(elem: SndMixerElemT,
                                               value: clong): cint
  {.importc, dynlib: libasound.}
