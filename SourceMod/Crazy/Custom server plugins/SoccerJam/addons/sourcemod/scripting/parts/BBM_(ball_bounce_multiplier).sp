Handle BallBounceMultiplierConVar;

public void BBM_Init()
{
	BallBounceMultiplierConVar = CreateConVar("sj_ball_bounce_multiplier", "0.85", "Ball bounce multiplier", 0, true, 0.0, true, 1.0);
}

public void BBM_OnBallCreated(int ballEntity)
{	
	SetEntPropFloat(ballEntity, Prop_Data, "m_flElasticity", GetConVarFloat(BallBounceMultiplierConVar));
}