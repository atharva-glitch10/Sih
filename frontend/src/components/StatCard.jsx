function StatCard({
  title,
  value,
  description,
  icon: Icon,
  type,
}) {
  return (
    <div className={`stat-card ${type}`}>

      <div className="stat-icon">
        <Icon size={22} />
      </div>

      <div className="stat-info">

        <span className="stat-title">
          {title}
        </span>

        <h2>
          {value.toLocaleString()}
        </h2>

        <p>
          {description}
        </p>

      </div>

    </div>
  );
}

export default StatCard;