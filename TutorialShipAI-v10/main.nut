/*
 * This file is part of TutorialShipAI, which is an AI for OpenTTD
 * Copyright (C) 2012  Leif Linse & William Minchin
 *
 * TutorialShipAI is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * TutorialShipAI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with TutorialShipAI; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street, 
 * Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

// Import SuperLib
import("util.superlib", "SuperLib", 26);

//Result <- SuperLib.Result;
//Log <- SuperLib.Log;
Helper <- SuperLib.Helper;
//ScoreList <- SuperLib.ScoreList;
//Money <- SuperLib.Money;
SLMoney <- SuperLib.Money;
//
//Tile <- SuperLib.Tile;
//Direction <- SuperLib.Direction;
//
//Engine <- SuperLib.Engine;
//Vehicle <- SuperLib.Vehicle;
//
//Station <- SuperLib.Station;
//Airport <- SuperLib.Airport;
//Industry <- SuperLib.Industry;
//Town <- SuperLib.Town;
//
//Order <- SuperLib.Order;
//OrderList <- SuperLib.OrderList;
//
//Road <- SuperLib.Road;
//RoadBuilder <- SuperLib.RoadBuilder;

/* Import MinchinWeb's MetaLibrary */
import("util.MinchinWeb", "MetaLib", 5);
	OpLog <- MetaLib.Log;
	mwLog <- MetaLib.Log;
	Array <- MetaLib.Array;
	Marine <- MetaLib.Marine;
	
require("OpMoney.nut");
require("Tutorial.OpHibernia.nut");

class MainClass extends AIController 
{
	constructor() {

	}
}

function MainClass::Start()
{
	this.Sleep(1);
	mwLog.Note("Tutorial Ship building is running. Waiting for start prompt...", 1);

	// Wait on start trigger from GS
	local table = this.WaitForStart();

	// Build ship connection
	
	for (local deltaX = 0; deltaX >= -2; deltaX--) {
		mwLog.Note("deltaX = " + deltaX, 4);

		//	Build Locks
		GSMarine.BuildLock(GSMap.GetTileIndex(GSMap.GetTileX(table.canal_lock1) + deltaX, GSMap.GetTileY(table.canal_lock1)));
		GSMarine.BuildLock(GSMap.GetTileIndex(GSMap.GetTileX(table.canal_lock2) + deltaX, GSMap.GetTileY(table.canal_lock2)));	

		//	Build Canals
		local LW = MetaLib.LineWalker();
		LW.Start(GSMap.GetTileIndex(GSMap.GetTileX(table.canal_start_tile) + deltaX, GSMap.GetTileY(table.canal_start_tile)));
		LW.End(GSMap.GetTileIndex(GSMap.GetTileX(table.canal_end_tile) + deltaX, GSMap.GetTileY(table.canal_end_tile)));

		do {
			local mytile = LW.Walk();
			GSMarine.BuildCanal(mytile);
		} while (!LW.IsEnd())
	}
	
	//	Build Ships
	local ShipRouteBuilder = OpHibernia();
	ShipRouteBuilder.Run(table.oilrig1, table.refinery);
	ShipRouteBuilder.Run(table.oilrig2, table.refinery);	

	// Tell GS that we are done
	this.TellGSThatWeAreDone();


	// Nothing more to do. Sleep forever.
	while(true) {
		this.Sleep(100);
	}
}

/*
 * This method wait for the start trigger to build a connection for the
 * ship chapter route.
 *
 * When (if) the start trigger is received, this method reads the industry
 * ids and tile locations that is passed from the GS to this AI and return
 * all data in a table.
 */
function MainClass::WaitForStart()
{
	while(!Helper.HasSign("$Start"))
	{
		this.Sleep(10);
	}

	// $Start found => remove it
	AISign.RemoveSign(Helper.GetSign("$Start"));

	// Find the industry + canal data
	local ind_list = [];
	local canal_list = [];

	local sign_list = AISignList();
	foreach(sign, _ in sign_list)
	{
		local text = AISign.GetName(sign);
		local start = text.slice(0, 3);
		AILog.Info("|" + start + "|");
		if (start == "$I:") {
			ind_list = Helper.SplitString("|", text.slice(3));
			AISign.RemoveSign(sign);
		}
		else if (start == "$C:") {
			canal_list = Helper.SplitString("|", text.slice(3));
			AISign.RemoveSign(sign);
		}
	}

	if (ind_list.len() < 3 || canal_list.len() < 4)
		throw Exception("Couldn't get ship chapter data.");

	local table = {};
	table.refinery <- ind_list[0];
	table.oilrig1 <- ind_list[1];
	table.oilrig2 <- ind_list[2];
	table.canal_start_tile <- canal_list[0];
	table.canal_end_tile <- canal_list[1];
	table.canal_lock1 <- canal_list[2];
	table.canal_lock2 <- canal_list[3];

	return table;
}

/*
 * Call this method to tell the GS that we are done constructing the ship
 * routes.
 */
function MainClass::TellGSThatWeAreDone()
{
	local sign_tile = AIMap.GetTileIndex(1, 1);
	AISign.BuildSign(sign_tile, "$Done");
}

/*
 * Call this method to tell the GS that we failed to construct the ship
 * routes and we now give up.
 */
function MainClass::TellGSThatWeFailed()
{
	local sign_tile = GSMap.GetTileIndex(1, 1);
	GSSign.BuildSign(sign_tile, "$Failed");
}

function MainClass::Save()
{
	return { 
	};
}
