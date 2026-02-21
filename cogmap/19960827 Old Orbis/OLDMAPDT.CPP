void MapDoc::dt(int timeSlices) {
	for (int i = 0; i < 3; i++) {
		POSITION pos = GetStartPosition();
		// REAL sel = (REAL)rand()/(REAL)RAND_MAX;
		MapItem *item;
		// ASSERT(totSpeed >= 0.0);
		// while ((pos != NULL) && (sel > 0)) {
			item = (MapItem *)GetNextItem(pos);
		//	sel -= 1/(REAL)(m_docItemList.GetCount());
			// sel -= item->sqrtSpeed()/totSqrtSpeed();
		// }   // while
		//ASSERT(item != NULL);
		item->dt();
	}	// for
	t += 1;
	temp *= (REAL)0.90;   // annealing
}   // MapDoc::dt
