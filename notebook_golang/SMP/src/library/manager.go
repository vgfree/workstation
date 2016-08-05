package library

import "error"

type Music struct {
	Id string,
	Name string,
	Artist string,
	Source string,
	Type string,
}

type MusicManager struct {
	musics []MusicEntry
}




